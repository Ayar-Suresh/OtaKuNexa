import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SassyBotUI — Modern Anime-Style Chat Overlay
// No audio / TTS — pure text chat with typewriter animation
// ─────────────────────────────────────────────────────────────────────────────
class SassyBotUI extends StatefulWidget {
  const SassyBotUI({super.key});

  @override
  State<SassyBotUI> createState() => _SassyBotUIState();
}

class _SassyBotUIState extends State<SassyBotUI> with TickerProviderStateMixin {
  // Breathing animation for the floating bubble
  late AnimationController _breathingController;

  // Thinking dots animation
  late AnimationController _dotsController;

  // Drag position of the floating widget
  Offset _position = const Offset(20, 100);

  // Chat input controller
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  // Typewriter animation state
  String _displayedMessage = '';
  Timer? _typewriterTimer;
  String _targetMessage = '';

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Listen for new messages → trigger typewriter
    SassyAiService.instance.currentMessage.addListener(_onNewMessage);
  }

  void _onNewMessage() {
    final msg = SassyAiService.instance.currentMessage.value;
    if (msg == _targetMessage) return; // Only process if the message actually changed
    _startTypewriter(msg);
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    _targetMessage = text;
    _displayedMessage = text.isNotEmpty ? text[0] : ''; // Prevent empty string glitches
    
    // Immediately show first character
    if (mounted && text.isNotEmpty) {
      setState(() {});
    }

    int index = 1;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 35), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (index < _targetMessage.length) {
        // Safe setState mechanism to avoid during-build exceptions
        final applyState = () {
          if (mounted) {
            setState(() => _displayedMessage = _targetMessage.substring(0, index + 1));
          }
        };
        
        if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
          SchedulerBinding.instance.addPostFrameCallback((_) => applyState());
        } else {
          applyState();
        }
        index++;
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _dotsController.dispose();
    _typewriterTimer?.cancel();
    SassyAiService.instance.currentMessage.removeListener(_onNewMessage);
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _submitInput() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      if (SassyAiService.instance.isWaitingForAnimeInput.value) {
        SassyAiService.instance.processGhostAutomation(text);
      } else {
        SassyAiService.instance.askGroq(text);
      }
      _inputController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SassyAiService.instance.isVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: ValueListenableBuilder<bool>(
            valueListenable: SassyAiService.instance.isExpanded,
            builder: (context, isExpanded, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: isExpanded
                    ? _buildExpandedChat()
                    : GestureDetector(
                        onPanUpdate: (d) => setState(() => _position += d.delta),
                        onTap: () {
                          if (!SassyAiService.instance.isExpanded.value) {
                            SassyAiService.instance.isExpanded.value = true;
                          }
                        },
                        child: _buildFloatingBubble(),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Floating Bubble ────────────────────────────────────────────────────────
  Widget _buildFloatingBubble() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, _) {
        final scale = 1.0 + (_breathingController.value * 0.06);
        return ValueListenableBuilder<bool>(
          valueListenable: SassyAiService.instance.isThinking,
          builder: (context, isThinking, _) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isThinking
                        ? [const Color(0xFF9D4EDD), const Color(0xFF7B2CBF)]
                        : [const Color(0xFFFF7EB3), const Color(0xFFFF5C8D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isThinking
                              ? const Color(0xFF9D4EDD)
                              : const Color(0xFFFF5C8D))
                          .withOpacity(0.55),
                      blurRadius: 18.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    isThinking ? '⊙_⊙' : '^_^',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Expanded Chat Panel ────────────────────────────────────────────────────
  Widget _buildExpandedChat() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          // Glassmorphism-style dark panel
          color: const Color(0xFF12121E).withOpacity(0.96),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: const Color(0xFFFF7EB3).withOpacity(0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5C8D).withOpacity(0.18),
              blurRadius: 28.r,
              spreadRadius: 2.r,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: 10.h),
            _buildMessageBubble(),
            SizedBox(height: 10.h),
            _buildHelpButtons(),
            _buildInputRow(),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return GestureDetector(
      onPanUpdate: (d) => setState(() => _position += d.delta),
      child: Container(
        color: Colors.transparent, // Required to capture drags on empty space
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Row(children: [
          // Status dot
          ValueListenableBuilder<bool>(
            valueListenable: SassyAiService.instance.isThinking,
            builder: (_, isThinking, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isThinking
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF44FF88),
                boxShadow: [
                  BoxShadow(
                    color: (isThinking
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF44FF88))
                        .withOpacity(0.8),
                    blurRadius: 6.r,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'SassyBot ✨',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15.sp,
              letterSpacing: 0.3,
            ),
          ),
        ]),
        // Close
        GestureDetector(
          onTap: () => SassyAiService.instance.isExpanded.value = false,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: Colors.white54, size: 16.sp),
          ),
        ),
      ],
     ),
    ),
   );
  }

  // ─── Message Bubble with Typewriter ─────────────────────────────────────────
  Widget _buildMessageBubble() {
    return ValueListenableBuilder<bool>(
      valueListenable: SassyAiService.instance.isThinking,
      builder: (context, isThinking, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isThinking
                  ? [
                      const Color(0xFF9D4EDD).withOpacity(0.15),
                      const Color(0xFF7B2CBF).withOpacity(0.08),
                    ]
                  : [
                      const Color(0xFFFF7EB3).withOpacity(0.12),
                      const Color(0xFF1A1A2E).withOpacity(0.0),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isThinking
                  ? const Color(0xFF9D4EDD).withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: isThinking ? _buildThinkingDots() : _buildTypewriterText(),
        );
      },
    );
  }

  Widget _buildThinkingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        final phase = (_dotsController.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14.sp, color: const Color(0xFFE0AAFF)),
            SizedBox(width: 6.w),
            Text(
              'thinking${['...', '.. ', '.  '][phase % 3]}',
              style: TextStyle(
                color: const Color(0xFFE0AAFF),
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypewriterText() {
    return Text(
      _displayedMessage,
      style: TextStyle(
        color: Colors.white.withOpacity(0.92),
        fontSize: 13.sp,
        height: 1.55,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  // ─── Help Flow Buttons ───────────────────────────────────────────────────────
  Widget _buildHelpButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: SassyAiService.instance.isWaitingForHelpResponse,
      builder: (_, waiting, __) {
        if (!waiting) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _helpButton('Yes! 🙋', const Color(0xFFFF5C8D), () {
                SassyAiService.instance.handleHelpResponse(true);
              }),
              _helpButton('Nah 🙅', const Color(0xFF3A3A5C), () {
                SassyAiService.instance.handleHelpResponse(false);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _helpButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8.r),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  // ─── Chat Input Row ──────────────────────────────────────────────────────────
  Widget _buildInputRow() {
    return ValueListenableBuilder<bool>(
      valueListenable: SassyAiService.instance.isWaitingForHelpResponse,
      builder: (_, waitingForHelp, __) {
        if (waitingForHelp) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: SassyAiService.instance.isWaitingForAnimeInput,
          builder: (_, waitingForAnime, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: SassyAiService.instance.isThinking,
              builder: (_, isThinking, __) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        enabled: !isThinking,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText: isThinking
                              ? 'SassyBot is thinking...'
                              : waitingForAnime
                                  ? 'Enter anime title... 🔍'
                                  : 'Ask me anything... 💬',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 13.sp,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.07),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF7EB3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submitInput(),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: isThinking ? null : _submitInput,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(11.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isThinking
                                ? [Colors.grey.shade700, Colors.grey.shade800]
                                : [
                                    const Color(0xFFFF7EB3),
                                    const Color(0xFFFF5C8D),
                                  ],
                          ),
                          boxShadow: isThinking
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFFF5C8D)
                                        .withOpacity(0.5),
                                    blurRadius: 10.r,
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 17.sp,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
