import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import 'register_controller.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;

    return ChangeNotifierProvider(
      create: (_) => RegisterController(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.isDarkMode
                  ? const [
                      Color(0xFF28405A),
                      Color(0xFF35506F),
                      Color(0xFF3E5D80),
                      Color(0xFF304A68),
                    ]
                  : const [
                      Color(0xFFF8FAFC),
                      Color(0xFFE5E7EB),
                      Color(0xFFD1D5DB),
                      Color(0xFFF3F4F6),
                    ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 0 : 24,
                      vertical: 40,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isWeb ? 520 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          const _RegisterLogo(),
                          const SizedBox(height: 32),
                          _RegisterHeader(themeProvider.isDarkMode),
                          const SizedBox(height: 32),
                          _RegisterCard(isDarkMode: themeProvider.isDarkMode),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: _RegisterThemeModeSwitch(themeProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterLogo extends StatelessWidget {
  const _RegisterLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  final bool isDarkMode;

  const _RegisterHeader(this.isDarkMode);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      children: [
        Text(
          lang.getText('createAccount'),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lang.getText('registerSubtitle'),
          style: TextStyle(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.86)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatefulWidget {
  final bool isDarkMode;

  const _RegisterCard({required this.isDarkMode});

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit(RegisterController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await controller.register();
    if (!success || !mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? const Color(0xFF3A5678).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode
                  ? const Color(0xFF7E9CBC)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText('usernameLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.usernameController,
                  decoration: InputDecoration(
                    hintText: lang.getText('usernameHint'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return lang.getText('usernameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  lang.getText('emailLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: lang.getText('emailHint'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return lang.getText('emailRequired');
                    }
                    if (!value.contains('@')) {
                      return lang.getText('emailInvalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  lang.getText('passwordLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: lang.getText('passwordHint'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return lang.getText('passwordRequired');
                    }
                    if (value.length < 6) {
                      return lang.getText('passwordShort');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  lang.getText('confirmPasswordLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: controller.obscureConfirmPassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: lang.getText('confirmPasswordHint'),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return lang.getText('confirmPasswordRequired');
                    }
                    if (value != controller.passwordController.text) {
                      return lang.getText('passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => _submit(controller),
                    child: controller.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(lang.getText('registerButton')),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(lang.getText('alreadyHaveAccount')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterThemeModeSwitch extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _RegisterThemeModeSwitch(this.themeProvider);

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF3A5678),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF7E9CBC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RegisterThemeChip(
            label: 'Light',
            icon: Icons.wb_sunny_outlined,
            selected: !isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          const SizedBox(width: 6),
          _RegisterThemeChip(
            label: 'Dark',
            icon: Icons.nights_stay_rounded,
            selected: isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _RegisterThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RegisterThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFFF1F5F9);

    return Material(
      color: selected ? const Color(0xFFE84537) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
