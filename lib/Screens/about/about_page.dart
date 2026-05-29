import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(isDark: isDark),
            const SizedBox(height: 32),
            _SectionCard(
              isDark: isDark,
              accentColor: Colors.blueAccent,
              icon: Icons.shield_outlined,
              title: lang.isArabic ? "ماذا نفعل" : "What We Do",
              body: lang.isArabic
                  ? "SMF (Smooth Monitoring & Fortification) هو نظام مراقبة أمنية متكامل يوفر رصدًا فوريًا للأجهزة والمستخدمين والتنبيهات الأمنية عبر لوحة تحكم واحدة موحدة."
                  : "SMF (Smooth Monitoring & Fortification) is a unified security monitoring platform that provides real-time oversight of devices, users, and security alerts — all from a single, powerful dashboard.",
            ),
            const SizedBox(height: 16),
            _AdvantagesCard(isDark: isDark, lang: lang),
            const SizedBox(height: 16),
            _MissionVisionCard(isDark: isDark, lang: lang),
            const SizedBox(height: 32),
            Center(
              child: Text(
                "© SMF Smooth Monitoring and Fortification",
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final bool isDark;
  const _HeroBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A2A4A), Color(0xFF0D1B36)]
              : const [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ✅ REAL SMF LOGO — replaces the old shield icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png', // ✅ CORRECT PATH
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "SMF",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Smooth Monitoring\n& Fortification",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Securing your environment — in real time.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(label: "210+ Users",  icon: Icons.people_outline),
              _StatPill(label: "185 Devices", icon: Icons.devices_outlined),
              _StatPill(label: "24/7 Live",   icon: Icons.circle, iconColor: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatPill({
    required this.label,
    required this.icon,
    this.iconColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic Section Card
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String body;

  const _SectionCard({
    required this.isDark,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advantages Card
// ─────────────────────────────────────────────────────────────────────────────
class _AdvantagesCard extends StatelessWidget {
  final bool isDark;
  final LanguageProvider lang;

  const _AdvantagesCard({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final advantages = lang.isArabic
        ? [
            {"icon": Icons.bolt,     "color": Colors.orange,     "title": "مراقبة فورية",       "desc": "تتبع مباشر للأجهزة والمستخدمين على مدار الساعة"},
            {"icon": Icons.campaign, "color": Colors.redAccent,  "title": "تنبيهات ذكية",        "desc": "إشعارات فورية للحوادث الأمنية الحرجة"},
            {"icon": Icons.language, "color": Colors.teal,       "title": "دعم متعدد اللغات",    "desc": "واجهة كاملة بالعربية والإنجليزية"},
            {"icon": Icons.devices,  "color": Colors.blueAccent, "title": "إدارة الأجهزة",       "desc": "مراقبة وإدارة شاملة لجميع الأجهزة المتصلة"},
          ]
        : [
            {"icon": Icons.bolt,     "color": Colors.orange,     "title": "Real-Time Monitoring","desc": "Live tracking of all devices and users around the clock"},
            {"icon": Icons.campaign, "color": Colors.redAccent,  "title": "Smart Alerts",        "desc": "Instant notifications for critical security incidents"},
            {"icon": Icons.language, "color": Colors.teal,       "title": "Bilingual Support",   "desc": "Full Arabic & English interface for all users"},
            {"icon": Icons.devices,  "color": Colors.blueAccent, "title": "Device Management",  "desc": "Comprehensive oversight of all connected devices"},
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Text(
                lang.isArabic ? "لماذا نحن الأفضل" : "Why We're the Best",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...advantages.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (item["color"] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item["icon"] as IconData,
                        color: item["color"] as Color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item["title"] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 3),
                        Text(item["desc"] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission & Vision Card
// ─────────────────────────────────────────────────────────────────────────────
class _MissionVisionCard extends StatelessWidget {
  final bool isDark;
  final LanguageProvider lang;

  const _MissionVisionCard({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            isDark: isDark,
            icon: Icons.flag_outlined,
            color: Colors.green,
            title: lang.isArabic ? "مهمتنا" : "Mission",
            body: lang.isArabic
                ? "توفير بيئة آمنة من خلال مراقبة ذكية وفورية"
                : "Deliver smart, real-time protection for every environment we serve.",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniCard(
            isDark: isDark,
            icon: Icons.visibility_outlined,
            color: Colors.purpleAccent,
            title: lang.isArabic ? "رؤيتنا" : "Vision",
            body: lang.isArabic
                ? "أن نكون المنصة الأمنية الأولى في المنطقة"
                : "Become the leading security monitoring platform across the region.",
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _MiniCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 12,
                height: 1.5,
              )),
        ],
      ),
    );
  }
}