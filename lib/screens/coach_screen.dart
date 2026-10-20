import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/quick_prompts.dart';
import '../models/chat_message.dart';
import '../state/app_state.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/formatted_text.dart';
import 'ai_connection_screen.dart';

/// Real AI chat with FitCoach AI. Every answer comes from the backend; if the backend
/// cannot be reached the user is told so, and nothing is invented.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _pendingCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  /// A prompt tapped elsewhere (Home, Plan) is sent as soon as this tab is showing.
  void _consumePendingPrompt(AppState state) {
    if (_pendingCheckScheduled) return;
    if (state.selectedTab != AppTab.coach || state.pendingPrompt == null) return;
    _pendingCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingCheckScheduled = false;
      if (!mounted) return;
      final prompt = state.takePendingPrompt();
      if (prompt != null) state.sendChat(prompt);
    });
  }

  Future<void> _send(AppState state) async {
    final text = _controller.text.trim();
    if (text.isEmpty || state.sending) return;
    _controller.clear();
    await state.sendChat(text);
    final code = state.lastError?.code;
    // Rejected before sending: give the text back so nothing the user typed is lost.
    if ((code == 'too_long' || code == 'slow_down') && mounted && _controller.text.isEmpty) {
      _controller.text = text;
    }
  }

  Future<void> _clearChat(AppState state) async {
    final ok = await confirmDialog(
      context,
      title: 'Clear conversation?',
      message: 'This removes your chat history from this phone. Saved plans are kept.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (ok) await state.clearChat();
  }

  void _openConnection() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const AiConnectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _consumePendingPrompt(state);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showEmpty = state.chat.isEmpty && !state.sending;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          _buildHeader(state),
          Expanded(child: showEmpty ? _buildEmpty(state) : _buildMessages(state)),
          if (state.lastError != null) _buildError(state),
          if (!showEmpty && !keyboardOpen) _buildPromptRow(state),
          _buildInput(state),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('YOUR COACH', style: AppText.label),
                const SizedBox(height: 4),
                Text(AppConfig.coachName, style: AppText.h1.copyWith(fontSize: 26)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'clear') {
                _clearChat(state);
              } else if (value == 'connection') {
                _openConnection();
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'clear', child: Text('Clear conversation')),
              PopupMenuItem<String>(value: 'connection', child: Text('AI connection')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppState state) {
    final notConnected = state.backendUrl.trim().isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: <Widget>[
        const SizedBox(height: 8),
        const Center(child: BrandMark(size: 64, onDark: false)),
        const SizedBox(height: 16),
        Text(
          'Hello ${state.profile.displayName}, I am FitCoach.',
          textAlign: TextAlign.center,
          style: AppText.h2,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask me about affordable Kenyan meals, home workouts, portions or staying consistent.',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 18),
        if (notConnected) ...<Widget>[
          AppCard(
            color: AppColors.dangerSoft,
            borderColor: AppColors.dangerSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.cloud_off_outlined, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('AI server not connected yet', style: AppText.h3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live answers come from your own FitCoach server. Paste its address once and chat will work.',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _openConnection, child: const Text('Connect AI server')),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SectionLabel('Try asking'),
        for (final prompt in kQuickPrompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: state.sending ? null : () => state.sendChat(prompt),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(prompt, style: AppText.body)),
                  const Icon(Icons.arrow_forward, size: 18, color: AppColors.forest),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const InfoBanner(
          icon: Icons.wifi_off,
          text: 'Live chat needs internet. Tracking, meal ideas, workouts and saved plans work offline.',
        ),
      ],
    );
  }

  Widget _buildMessages(AppState state) {
    final reversed = state.chat.reversed.toList();
    final extra = state.sending ? 1 : 0;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: reversed.length + extra,
      itemBuilder: (BuildContext context, int index) {
        if (state.sending && index == 0) return const _TypingBubble();
        final message = reversed[index - extra];
        return _MessageBubble(message: message, state: state);
      },
    );
  }

  Widget _buildError(AppState state) {
    final error = state.lastError!;
    const setupCodes = <String>{
      'not_configured',
      'bad_url',
      'not_found',
      'unauthorized',
      'server_not_configured',
    };
    final needsSetup = setupCodes.contains(error.code);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.error_outline, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(error.message, style: AppText.body),
                ),
              ),
              IconButton(
                onPressed: state.dismissError,
                tooltip: 'Dismiss message',
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          Wrap(
            children: <Widget>[
              if (state.canRetry && !needsSetup)
                TextButton.icon(
                  onPressed: state.retryLast,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                ),
              if (needsSetup)
                TextButton.icon(
                  onPressed: _openConnection,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('AI connection'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptRow(AppState state) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        itemCount: kQuickPrompts.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final prompt = kQuickPrompts[index];
          return ActionChip(
            label: Text(prompt),
            onPressed: state.sending ? null : () => state.sendChat(prompt),
            backgroundColor: AppColors.card,
            side: const BorderSide(color: AppColors.border),
            labelStyle: const TextStyle(fontSize: 13, color: AppColors.forest, fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }

  Widget _buildInput(AppState state) {
    final canSend = !state.sending && _controller.text.trim().isNotEmpty;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: color),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: AppConfig.maxMessageChars,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Ask FitCoach anything...',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    enabledBorder: border(AppColors.border),
                    focusedBorder: border(AppColors.forest),
                    border: border(AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? () => _send(state) : null,
                tooltip: 'Send message',
                icon: const Icon(Icons.arrow_upward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.ivory,
                  disabledBackgroundColor: AppColors.sageLight,
                  disabledForegroundColor: AppColors.muted,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI can make mistakes. General guidance only, not medical advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.state});

  final ChatMessage message;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.86;
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: SelectableText(
                message.text,
                style: AppText.body.copyWith(color: AppColors.ivory),
              ),
            ),
          ),
        ),
      );
    }

    final saved = state.isSaved(message);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FormattedText(message.text),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: message.text));
                        if (context.mounted) showSnack(context, 'Copied to clipboard');
                      },
                      tooltip: 'Copy answer',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.content_copy, size: 18, color: AppColors.muted),
                    ),
                    IconButton(
                      onPressed: saved
                          ? null
                          : () async {
                              await state.savePlan(message);
                              if (context.mounted) {
                                showSnack(context, 'Saved. Find it under Plan, then Meals, then Saved plans.');
                              }
                            },
                      tooltip: saved ? 'Already saved' : 'Save for offline',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: saved ? AppColors.gold : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          liveRegion: true,
          label: 'FitCoach is thinking',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('FitCoach is thinking...', style: AppText.bodyMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
