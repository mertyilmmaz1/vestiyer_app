import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service_base.dart';
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

  String? _wardrobeContext;
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
    final userId = wardrobeProvider.currentUserId;
    final firestore = context.read<FirestoreServiceBase>();

    String? contextString;
    if (userId != null) {
      final saved = await firestore.getWardrobeAnalysis(userId);
      if (saved != null && saved.isNotEmpty) {
        contextString = _wardrobeContextFromSaved(saved);
      }
    }
    if (contextString == null || contextString.isEmpty) {
      contextString = _wardrobeContextFromProvider(wardrobeProvider);
      if (userId != null &&
          contextString.isNotEmpty &&
          contextString != 'Kullanıcının henüz dolabında kıyafet yok.') {
        final toSave = _buildMinimalAnalysisData(wardrobeProvider);
        if (toSave.isNotEmpty) {
          toSave['updatedAt'] = DateTime.now().toIso8601String();
          await firestore.setWardrobeAnalysis(userId, toSave);
        }
      }
    }
    if (mounted) {
      setState(() {
        _wardrobeContext = contextString ?? 'Kullanıcının dolap bilgisi yok.';
        _loadingContext = false;
      });
    }
  }

  String _wardrobeContextFromSaved(Map<String, dynamic> saved) {
    final buf = StringBuffer();
    final stats = saved['statistics'] as Map<String, dynamic>?;
    if (stats != null) {
      buf.writeln(
          'Toplam kıyafet: ${stats['total_items'] ?? 0}. Mevcut mevsim: ${stats['current_season'] ?? 'bilinmiyor'}.');
      final categoryCounts = stats['category_counts'] as Map<String, dynamic>?;
      if (categoryCounts != null && categoryCounts.isNotEmpty) {
        buf.write('Kategoriler: ');
        buf.write(categoryCounts.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', '));
        buf.writeln('.');
      }
      final styleDist =
          stats['style_distribution'] as Map<String, dynamic>?;
      if (styleDist != null && styleDist.isNotEmpty) {
        buf.write('Stil dağılımı: ');
        buf.write(styleDist.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', '));
        buf.writeln('.');
      }
    }
    final styleAnalysis = saved['style_analysis'] as String?;
    if (styleAnalysis != null && styleAnalysis.isNotEmpty) {
      buf.writeln('Stil analizi: $styleAnalysis');
    }
    final seasonalAnalysis = saved['seasonal_analysis'] as String?;
    if (seasonalAnalysis != null && seasonalAnalysis.isNotEmpty) {
      buf.writeln('Mevsimsel analiz: $seasonalAnalysis');
    }
    final recommendations = saved['recommendations'] as List<dynamic>?;
    if (recommendations != null && recommendations.isNotEmpty) {
      buf.writeln('Öneriler: ${recommendations.join(' ')}');
    }
    return buf.toString().trim();
  }

  String _wardrobeContextFromProvider(WardrobeProvider provider) {
    final items = provider.items;
    if (items.isEmpty) {
      return 'Kullanıcının henüz dolabında kıyafet yok.';
    }
    final buf = StringBuffer();
    buf.writeln('Toplam kıyafet: ${items.length}.');
    final categoryStats = provider.getCategoryStats();
    if (categoryStats.isNotEmpty) {
      buf.write('Kategoriler: ');
      buf.write(categoryStats.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '));
      buf.writeln('.');
    }
    final seasonStats = provider.getSeasonStats();
    if (seasonStats.isNotEmpty) {
      buf.write('Mevsim dağılımı: ');
      buf.write(seasonStats.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '));
      buf.writeln('.');
    }
    buf.writeln(provider.getFormattedClothingItems());
    return buf.toString().trim();
  }

  Map<String, dynamic> _buildMinimalAnalysisData(WardrobeProvider provider) {
    final items = provider.items;
    if (items.isEmpty) return {};
    final categoryStats = provider.getCategoryStats();
    final seasonStats = provider.getSeasonStats();
    final styleDistribution = <String, int>{};
    for (final item in items) {
      final style = item.advancedAnalysis?.style ?? 'Belirsiz';
      styleDistribution[style] = (styleDistribution[style] ?? 0) + 1;
    }
    final now = DateTime.now();
    final month = now.month;
    final currentSeason = month >= 3 && month <= 5
        ? 'İlkbahar'
        : month >= 6 && month <= 8
            ? 'Yaz'
            : month >= 9 && month <= 11
                ? 'Sonbahar'
                : 'Kış';
    final currentSeasonItems = items
        .where((c) =>
            c.advancedAnalysis?.season
                ?.toLowerCase()
                .contains(currentSeason.toLowerCase()) ==
                true ||
            c.advancedAnalysis?.season?.toLowerCase() == 'tüm sezon' ||
            c.advancedAnalysis?.season?.toLowerCase() == 'all-season')
        .length;
    return {
      'statistics': {
        'total_items': items.length,
        'current_season': currentSeason,
        'category_counts': categoryStats,
        'season_counts': seasonStats,
        'current_season_items': currentSeasonItems,
        'style_distribution': styleDistribution,
      },
      'recommendations': <String>[
        items.length < 10
            ? 'Dolabınızı genişletmek için daha fazla kıyafet ekleyebilirsiniz.'
            : 'Dolabınız güzel bir denge içinde görünüyor.',
      ],
      'style_analysis': styleDistribution.isEmpty
          ? 'Henüz stil analizi için yeterli veri yok.'
          : 'Stil dağılımı: ${styleDistribution.entries.map((e) => '${e.key}: ${e.value}').join(', ')}.',
      'seasonal_analysis':
          'Mevcut mevsim ($currentSeason) için $currentSeasonItems kıyafet bulunuyor.',
    };
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

    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    while (history.length > 20) {
      history.removeAt(0);
    }
    history.removeLast(); // current user message is sent as 'message', not in history

    try {
      final functions = context.read<CloudFunctionsService>();
      final result = await functions.getStyleAdvice(
        trimmed,
        conversationHistory: history,
        wardrobeContext: _wardrobeContext,
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
      appBar: AppBar(
        title: const Text(
          'Vestiyer Asistanı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loadingContext
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Column(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                _buildInputRow(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage m, int index, bool isTyping) {
    final isUser = m.role == 'user';
    final displayContent = isTyping
        ? m.content.substring(0, _typingVisibleLength.clamp(0, m.content.length))
        : m.content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.style,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.tertiary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      displayContent,
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (isTyping)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: _TypingCursor(),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Kombin veya stil hakkında sor...',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              enabled: !_sending,
              onSubmitted: (_) => _sendMessage(_inputController.text),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _sending
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _sending
                  ? null
                  : () => _sendMessage(_inputController.text),
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
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
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
