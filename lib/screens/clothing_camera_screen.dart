import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../widgets/camera_guides.dart';
import '../widgets/bouncing_widget.dart';
import '../core/product/theme/app_typography.dart';
import '../core/product/theme/app_spacing.dart';

class ClothingCameraScreen extends StatefulWidget {
  const ClothingCameraScreen({super.key});

  @override
  State<ClothingCameraScreen> createState() => _ClothingCameraScreenState();
}

class _ClothingCameraScreenState extends State<ClothingCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _showGuide = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _onNewCameraSelected(_cameras![_selectedCameraIndex]);
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      // Set fixed aspect ratio if possible, or we will handle it in the UI
      // Most cameras are 4:3 or 16:9. We want to display 3:4 (portrait 4:3)
    } on CameraException catch (e) {
      debugPrint('Camera error: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = _controller?.value.isInitialized ?? false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, File(file.path));
      }
    } on CameraException catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  void _toggleFlash() {
    if (_controller == null) return;

    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
      _controller!.setFlashMode(_flashMode);
    });
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _onNewCameraSelected(_cameras![_selectedCameraIndex]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Guide Overlay
          if (_showGuide) _buildGuideOverlay(),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleFlash,
                  child: HugeIcon(
                    icon: _flashMode == FlashMode.off
                        ? HugeIcons.strokeRoundedFlashOff
                        : HugeIcons.strokeRoundedFlash,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showGuide = !_showGuide),
                  child: const HugeIcon(
                    icon:
                        HugeIcons.strokeRoundedCircle, // Changed from WallClock
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(
                    width: 60), // Spacer for centering capture button
                _buildCaptureButton(),
                GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // We want a 3:4 aspect ratio box centered on the screen
        final double boxWidth = screenWidth;
        final double boxHeight = screenWidth * (4 / 3);

        // Aspect ratio of the camera source
        final double cameraAspectRatio = _controller!.value.aspectRatio;

        return Center(
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: boxWidth,
                    height: boxWidth * cameraAspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaptureButton() {
    return BouncingWidget(
      onTap: _takePicture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DAHA İYİ ANALİZ İÇİN İPUÇLARI',
            style: AppTypography.label.copyWith(
              color: Colors.white,
              letterSpacing: 2.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: PlainBackgroundGuide()),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: ClothingFittingGuide()),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: LightingGuide()),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl * 2),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => setState(() => _showGuide = false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 0.5),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              child: Text(
                'ANLADIM, BAŞLAYALIM',
                style: AppTypography.label.copyWith(
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
