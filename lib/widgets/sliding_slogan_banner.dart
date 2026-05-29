import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';

class SlidingSloganBanner extends StatefulWidget {
  const SlidingSloganBanner({super.key});

  @override
  State<SlidingSloganBanner> createState() => _SlidingSloganBannerState();
}

class _SlidingSloganBannerState extends State<SlidingSloganBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Fade OUT current slogan (0.0 → 0.4)
  late Animation<double> _fadeOut;

  // Slide IN next slogan (0.5 → 1.0)
  late Animation<Offset> _slideIn;

  // Fade IN next slogan (0.5 → 1.0)
  late Animation<double> _fadeIn;

  int _currentIndex = 0;
  bool _showingNext = false;
  int _nextIndex = 0;

  final List<Map<String, String>> _slogansEn = [
    {"icon": "🛡️", "text": "Security you can rely on"},
    {"icon": "👁️", "text": "Real-time monitoring, 24/7"},
    {"icon": "⚡", "text": "Instant alerts, zero delays"},
    {"icon": "🔒", "text": "Your safety is our priority"},
  ];

  final List<Map<String, String>> _slogansAr = [
    {"icon": "🛡️", "text": "أمان يمكنك الاعتماد عليه"},
    {"icon": "👁️", "text": "مراقبة فورية على مدار الساعة"},
    {"icon": "⚡", "text": "تنبيهات فورية بدون تأخير"},
    {"icon": "🔒", "text": "سلامتك هي أولويتنا"},
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Slower: 1200ms total animation duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Phase 1 (0.0→0.4): current slogan fades OUT
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Phase 2 (0.5→1.0): next slogan slides up from bottom
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Phase 2 (0.5→1.0): next slogan fades IN
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addListener(() {
      // Switch to showing next slogan at the halfway point
      if (_controller.value >= 0.45 && !_showingNext) {
        setState(() {
          _showingNext = true;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _showingNext = false;
        });
        _controller.reset();
        // ✅ Slower: stays on screen for 4 seconds before transitioning
        Future.delayed(const Duration(seconds: 4), _startTransition);
      }
    });

    // Initial delay before first transition
    Future.delayed(const Duration(seconds: 4), _startTransition);
  }

  void _startTransition() {
    if (!mounted) return;
    _nextIndex = (_currentIndex + 1) % _slogansEn.length;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    final slogansEn = _slogansEn;
    final slogansAr = _slogansAr;

    final currentSlogan =
        lang.isArabic ? slogansAr[_currentIndex] : slogansEn[_currentIndex];
    final nextSlogan =
        lang.isArabic ? slogansAr[_nextIndex] : slogansEn[_nextIndex];

    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1E3A), const Color(0xFF102244)]
              : [const Color(0xFF1565C0), const Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.blueAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Current slogan: fades out ──────────────────────────
                if (!_showingNext)
                  Opacity(
                    opacity: _fadeOut.value.clamp(0.0, 1.0),
                    child: _buildSloganRow(currentSlogan),
                  ),

                // ── Next slogan: slides up + fades in ──────────────────
                if (_showingNext)
                  FractionalTranslation(
                    translation: _slideIn.value,
                    child: Opacity(
                      opacity: _fadeIn.value.clamp(0.0, 1.0),
                      child: _buildSloganRow(nextSlogan),
                    ),
                  ),

                // ── Idle state (no animation) ──────────────────────────
                if (!_controller.isAnimating && !_showingNext)
                  _buildSloganRow(currentSlogan),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSloganRow(Map<String, String> slogan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          slogan["icon"]!,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          slogan["text"]!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}