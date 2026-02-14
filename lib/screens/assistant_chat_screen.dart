import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../widgets/vestiyer_page_header.dart';
import '../widgets/bouncing_widget.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/cloud_functions_service.dart';
import '../utils/wardrobe_summary_builder.dart';
import '../widgets/paywall_widget.dart';

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({
    super.key,
    this.initialMessage,
  });

  /// If set, this message is shown in the input and can be sent automatically or pre-filled.
  final String? initialMessage;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  _ChatMessage({required this.role, required this.content});
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _wardrobeSummary;
  bool _loadingContext = true;
  bool _sending = false;
  String? _error;

  /// Index of the assistant message currently being "typed".
  int? _typingMessageIndex;
  int _typingVisibleLength = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      _inputController.text = widget.initialMessage!;
    }
    _loadWardrobeContext();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPremiumStatus();
    });
  }

  void _checkPremiumStatus() {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.isPremium) {
      PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'Vestiyer Asistanı premium üyeler için kullanılabilir. Stil danışmanlığı almak için premium olun.',
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const int _typingCharsPerTick = 2;
  static const Duration _typingInterval = Duration(milliseconds: 25);

  void _startTypewriterEffect() {
    _typingTimer?.cancel();
    final index = _typingMessageIndex!;
    if (index >= _messages.length) return;
    final fullContent = _messages[index].content;
    _typingTimer = Timer.periodic(_typingInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _typingVisibleLength += _typingCharsPerTick;
        if (_typingVisibleLength >= fullContent.length) {
          _typingVisibleLength = fullContent.length;
          _typingMessageIndex = null;
          _sending = false;
          timer.cancel();
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _loadWardrobeContext() async {
    if (!mounted) return;
    final wardrobeProvider = context.read<WardrobeProvider>();
    final items = wardrobeProvider.items;

    Map<String, dynamic> summary;
    if (items.isEmpty) {
      summary = {
        'counts': {
          'top': 0,
          'bottom': 0,
          'outerwear': 0,
          'shoes': 0,
          'dress': 0,
          'accessory': 0
        },
        'dominant_styles': <String>[],
        'dominant_colors': <String>[],
        'seasons': <String>[],
        'missing_categories': ['top', 'bottom', 'shoes'],
        'confidence_level': 'low',
        'total_items': 0,
      };
    } else {
      summary = buildWardrobeSummary(items);
    }

    if (mounted) {
      setState(() {
        _wardrobeSummary = summary;
        _loadingContext = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.isPremium) {
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'Vestiyer Asistanı premium üyeler için kullanılabilir. Stil danışmanlığı almak için premium olun.',
      );
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: trimmed));
      _error = null;
      _sending = true;
    });
    _inputController.clear();

    final history =
        _messages.map((m) => {'role': m.role, 'content': m.content}).toList();
    while (history.length > 5) {
      history.removeAt(0);
    }
    history
        .removeLast(); // current user message is sent as 'message', not in history

    try {
      final functions = context.read<CloudFunctionsService>();
      final result = await functions.getStyleAdvice(
        trimmed,
        conversationHistory: history,
        wardrobeSummary: _wardrobeSummary,
      );
      final response = result['response'] as String? ?? 'Yanıt alınamadı.';
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: response));
          _typingMessageIndex = _messages.length - 1;
          _typingVisibleLength = 0;
        });
        _scrollToBottom();
        _startTypewriterEffect();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: 'assistant',
              content: 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.',
            ),
          );
          _error = e.toString();
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loadingContext
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VestiyerPageHeader(
                    title: 'Vestiyer Asistanı',
                    showBackButton: true,
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VestiyerPageHeader(
                    title: 'Vestiyer Asistanı',
                    showBackButton: true,
                    onBack: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              final isTyping = index == _typingMessageIndex;
                              return _buildMessageBubble(m, index, isTyping);
                            },
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        _buildInputRow(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage m, int index, bool isTyping) {
    final isUser = m.role == 'user';
    final displayContent = isTyping
        ? m.content
            .substring(0, _typingVisibleLength.clamp(0, m.content.length))
        : m.content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Zara stili: İsim/Rol etiketi mesajın üstünde, küçük ve uppercase
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              isUser ? 'SİZ' : 'VESTİYER ASİSTANI',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isUser ? AppColors.textPrimary : AppColors.softBackground,
              border: isUser
                  ? null
                  : Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayContent,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isUser ? AppColors.background : AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (isTyping)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _TypingCursor(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.textPrimary,
                    width: 0.5,
                  ),
                ),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Stil veya kombin hakkında sor...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                enabled: !_sending,
                onSubmitted: (_) => _sendMessage(_inputController.text),
              ),
            ),
          ),
          const SizedBox(width: 16),
          BouncingWidget(
            child: Material(
              color: _sending ? AppColors.textSecondary : AppColors.textPrimary,
              child: InkWell(
                onTap:
                    _sending ? null : () => _sendMessage(_inputController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.background),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.background,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingCursor extends StatefulWidget {
  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 18,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
