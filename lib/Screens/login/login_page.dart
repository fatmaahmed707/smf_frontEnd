import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import 'forgot_password_page.dart';
import 'login_controller.dart';
import '../../widgets/google_sign_in_button_stub.dart'
    if (dart.library.html) '../../widgets/google_web_sign_in_button.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginController>.value(
      value: _controller,
      child: const _LoginPageView(),
    );
  }
}

class _LoginPageView extends StatelessWidget {
  const _LoginPageView();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;
    final isArabic = languageProvider.isArabic;
    final palette = _LoginPalette.resolve(isDark: isDark);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: palette.pageBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWeb = width >= 900;
            final isCompact = width < 700;
            final horizontalPadding = width >= 1200
                ? 32.0
                : width >= 900
                    ? 24.0
                    : 16.0;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.pageGradient,
                ),
              ),
              child: SafeArea(
                child: Scrollbar(
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 660 : 1020,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(isCompact ? 28 : 34),
                            border: Border.all(
                              color: palette.frameBorder,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.outerGlow,
                                blurRadius: isDark ? 48 : 34,
                                spreadRadius: isDark ? 4 : 1,
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: palette.frameGradient,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(isCompact ? 28 : 34),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.topCenter,
                                        radius: 1.12,
                                        colors: palette.headerAura,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _AtmospherePainter(
                                        palette: palette,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          top: isCompact ? 54 : 46,
                                        ),
                                        child: _HeroWorkersOverlay(
                                          isCompact: isCompact,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _SignalPainter(
                                        color: palette.signalColor,
                                        accent: palette.signalAccent,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isCompact ? 18 : 28,
                                    isCompact ? 18 : 24,
                                    isCompact ? 18 : 28,
                                    isCompact ? 20 : 24,
                                  ),
                                  child: Column(
                                    children: [
                                      _TopControls(
                                        isArabic: isArabic,
                                        isDark: isDark,
                                        palette: palette,
                                      ),
                                      SizedBox(height: isCompact ? 14 : 18),
                                      _HeaderSection(
                                        isArabic: isArabic,
                                        isCompact: isCompact,
                                        isWeb: isWeb,
                                        palette: palette,
                                      ),
                                      SizedBox(height: isCompact ? 18 : 22),
                                      _LoginCard(
                                        isDarkMode: isDark,
                                        isArabic: isArabic,
                                        isCompact: isCompact,
                                        palette: palette,
                                      ),
                                      SizedBox(height: isCompact ? 18 : 24),
                                      _FeatureFooter(
                                        isArabic: isArabic,
                                        isCompact: isCompact,
                                        palette: palette,
                                      ),
                                      SizedBox(height: isCompact ? 16 : 18),
                                      _FooterCaption(
                                        isDark: isDark,
                                        isArabic: isArabic,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final _LoginPalette palette;

  const _TopControls({
    required this.isArabic,
    required this.isDark,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _LanguageSegmentedControl(
          isArabic: isArabic,
          palette: palette,
        ),
        _ThemeModeToggle(
          isDark: isDark,
          palette: palette,
        ),
      ],
    );
  }
}

class _LanguageSegmentedControl extends StatelessWidget {
  final bool isArabic;
  final _LoginPalette palette;

  const _LanguageSegmentedControl({
    required this.isArabic,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LanguageProvider>();
    final items = isArabic
        ? const [
            _LanguageItem(code: 'AR', isArabic: true),
            _LanguageItem(code: 'EN', isArabic: false),
          ]
        : const [
            _LanguageItem(code: 'EN', isArabic: false),
            _LanguageItem(code: 'AR', isArabic: true),
          ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.toggleBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.toggleBorder),
        boxShadow: [
          BoxShadow(
            color: palette.softShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => _SegmentChip(
                label: item.code,
                selected: item.isArabic == isArabic,
                selectedGradient: palette.primaryButtonGradient,
                selectedBorderColor: palette.segmentSelectedBorder,
                selectedShadow: palette.segmentGlow,
                textColor: palette.segmentText,
                selectedTextColor: Colors.white,
                onTap: () {
                  if (item.isArabic != isArabic) {
                    provider.toggleLanguage();
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ThemeModeToggle extends StatelessWidget {
  final bool isDark;
  final _LoginPalette palette;

  const _ThemeModeToggle({
    required this.isDark,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.toggleBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.toggleBorder),
        boxShadow: [
          BoxShadow(
            color: palette.softShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconSegmentChip(
            icon: Icons.wb_sunny_rounded,
            selected: !isDark,
            selectedGradient: palette.themeLightGradient,
            selectedBorderColor: palette.segmentSelectedBorder,
            selectedShadow: palette.segmentGlow,
            iconColor: palette.themeInactiveIcon,
            selectedIconColor: palette.themeLightIcon,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _IconSegmentChip(
            icon: Icons.nightlight_round,
            selected: isDark,
            selectedGradient: palette.primaryButtonGradient,
            selectedBorderColor: palette.segmentSelectedBorder,
            selectedShadow: palette.segmentGlow,
            iconColor: palette.themeInactiveIcon,
            selectedIconColor: Colors.white,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final bool isArabic;
  final bool isCompact;
  final bool isWeb;
  final _LoginPalette palette;

  const _HeaderSection({
    required this.isArabic,
    required this.isCompact,
    required this.isWeb,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _LoginCopy.of(isArabic);

    return Column(
      children: [
        _GlowingLogo(
          isCompact: isCompact,
          isWeb: isWeb,
          palette: palette,
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Text(
          copy.projectName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: palette.projectNameColor,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: isCompact ? 10 : 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: copy.titleFirstPart,
                style: TextStyle(
                  fontFamily: _pageFontFamily(isArabic),
                  fontSize: isCompact ? 34 : 52,
                  fontWeight: FontWeight.w800,
                  color: palette.titlePrimary,
                  height: 1.06,
                ),
              ),
              TextSpan(
                text: ' ',
                style: TextStyle(
                  fontFamily: _pageFontFamily(isArabic),
                  fontSize: isCompact ? 34 : 52,
                ),
              ),
              TextSpan(
                text: copy.titleSecondPart,
                style: TextStyle(
                  fontFamily: _pageFontFamily(isArabic),
                  fontSize: isCompact ? 34 : 52,
                  fontWeight: FontWeight.w800,
                  color: palette.titleAccent,
                  height: 1.06,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DecorativeRule(
              palette: palette,
              width: isCompact ? 34 : 50,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                copy.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _pageFontFamily(isArabic),
                  fontSize: isCompact ? 16 : 17,
                  fontWeight: FontWeight.w500,
                  color: palette.subtitleColor,
                ),
              ),
            ),
            _DecorativeRule(
              palette: palette,
              width: isCompact ? 34 : 50,
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginCard extends StatefulWidget {
  final bool isDarkMode;
  final bool isArabic;
  final bool isCompact;
  final _LoginPalette palette;

  const _LoginCard({
    required this.isDarkMode,
    required this.isArabic,
    required this.isCompact,
    required this.palette,
  });

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = true;

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(
    BuildContext context,
    LoginController controller,
  ) async {
    if (_formKey.currentState!.validate()) {
      final success = await controller.login();
      if (success && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    }
  }

  Future<void> _openRegister(BuildContext context) async {
    final languageProvider = context.read<LanguageProvider>();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getText('registerSuccess')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final languageProvider = context.watch<LanguageProvider>();
    final copy = _LoginCopy.of(widget.isArabic);
    final palette = widget.palette;
    final compact = widget.isCompact;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.isCompact ? 520 : 480,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 26,
            compact ? 18 : 24,
            compact ? 16 : 26,
            compact ? 18 : 22,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 24 : 30),
            color: palette.cardBackground,
            border: Border.all(
              color: palette.cardBorder,
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: widget.isDarkMode ? 34 : 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _FieldGroup(
                  bubbleIcon: Icons.mail_rounded,
                  bubbleColor: palette.emailBubble,
                  bubbleGlow: palette.emailBubbleGlow,
                  label: copy.emailLabel,
                  input: TextFormField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    textAlign:
                        widget.isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: palette.inputText,
                      fontSize: compact ? 16 : 18,
                      fontFamily: 'Inter',
                    ),
                    onChanged: (_) => controller.clearError(),
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    decoration: _inputDecoration(
                      hintText: copy.emailHint,
                      palette: palette,
                      isArabic: widget.isArabic,
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.getText('emailRequired');
                      }
                      if (!value.contains('@')) {
                        return languageProvider.getText('emailInvalid');
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: compact ? 18 : 22),
                _FieldGroup(
                  bubbleIcon: Icons.lock_rounded,
                  bubbleColor: palette.passwordBubble,
                  bubbleGlow: palette.passwordBubbleGlow,
                  label: copy.passwordLabel,
                  input: TextFormField(
                    controller: controller.passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: true,
                    obscuringCharacter: '•',
                    autofillHints: const [AutofillHints.password],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    textAlign:
                        widget.isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: palette.inputText,
                      fontSize: compact ? 16 : 18,
                      fontFamily: 'Inter',
                    ),
                    onChanged: (_) => controller.clearError(),
                    onFieldSubmitted: (_) => _submitLogin(context, controller),
                    decoration: _inputDecoration(
                      hintText: copy.passwordHint,
                      palette: palette,
                      isArabic: widget.isArabic,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.getText('passwordRequired');
                      }
                      if (value.length < 6) {
                        return languageProvider.getText('passwordShort');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 20,
                  child: Align(
                    alignment: widget.isArabic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AnimatedOpacity(
                      opacity: controller.errorMessage == null ? 0 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        controller.errorMessage ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _pageFontFamily(widget.isArabic),
                          color: palette.errorText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 14 : 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _rememberMe = !_rememberMe);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: _rememberMe
                                    ? palette.checkFill
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _rememberMe
                                      ? palette.checkFill
                                      : palette.checkBorder,
                                  width: 1.4,
                                ),
                                boxShadow: _rememberMe
                                    ? [
                                        BoxShadow(
                                          color: palette.checkGlow,
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _rememberMe
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              copy.rememberMe,
                              style: TextStyle(
                                fontFamily: _pageFontFamily(widget.isArabic),
                                fontSize: compact ? 16 : 17,
                                fontWeight: FontWeight.w500,
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        foregroundColor: palette.linkAccent,
                      ),
                      child: Text(
                        copy.forgotPassword,
                        style: TextStyle(
                          fontFamily: _pageFontFamily(widget.isArabic),
                          fontSize: compact ? 16 : 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 16),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: palette.primaryButtonGradient,
                      ),
                      border: Border.all(color: palette.primaryButtonBorder),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primaryButtonGlow,
                          blurRadius: widget.isDarkMode ? 28 : 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => _submitLogin(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 14 : 18,
                          vertical: compact ? 14 : 18,
                        ),
                      ),
                      child: controller.isLoading
                          ? SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            )
                          : Row(
                              textDirection: widget.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              children: [
                                const _ActionBadge(
                                  icon: Icons.shield_outlined,
                                ),
                                Expanded(
                                  child: Text(
                                    copy.loginButton,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily:
                                          _pageFontFamily(widget.isArabic),
                                      fontSize: compact ? 20 : 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                _ActionArrow(
                                  isArabic: widget.isArabic,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 18 : 22),
                _DividerLabel(
                  text: copy.orContinueWith,
                  isArabic: widget.isArabic,
                  palette: palette,
                ),
                SizedBox(height: compact ? 14 : 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: GoogleWebSignInButton(
                    onSuccess: (session) async {
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/dashboard',
                          (route) => false,
                        );
                      }
                    },
                    onError: (message) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  ),
                ),
                SizedBox(height: compact ? 18 : 22),
                _SignUpLine(
                  isArabic: widget.isArabic,
                  palette: palette,
                  onTap: () => _openRegister(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final IconData bubbleIcon;
  final Color bubbleColor;
  final Color bubbleGlow;
  final String label;
  final Widget input;

  const _FieldGroup({
    required this.bubbleIcon,
    required this.bubbleColor,
    required this.bubbleGlow,
    required this.label,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;

    return Row(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldBubble(
          icon: bubbleIcon,
          bubbleColor: bubbleColor,
          glowColor: bubbleGlow,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontFamily: _pageFontFamily(isArabic),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF143592),
                ),
              ),
              const SizedBox(height: 10),
              input,
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldBubble extends StatelessWidget {
  final IconData icon;
  final Color bubbleColor;
  final Color glowColor;

  const _FieldBubble({
    required this.icon,
    required this.bubbleColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0B143A).withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.95),
        border: Border.all(
          color: bubbleColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: bubbleColor,
          size: 30,
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String text;
  final bool isArabic;
  final _LoginPalette palette;

  const _DividerLabel({
    required this.text,
    required this.isArabic,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Expanded(child: _DividerBeam(palette: palette)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: _pageFontFamily(isArabic),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: palette.secondaryText,
            ),
          ),
        ),
        Expanded(child: _DividerBeam(palette: palette)),
      ],
    );
  }
}

class _DividerBeam extends StatelessWidget {
  final _LoginPalette palette;

  const _DividerBeam({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.dividerFade,
                    palette.dividerActive,
                    palette.dividerActive,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.dividerDot,
              boxShadow: [
                BoxShadow(
                  color: palette.dividerGlow,
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpLine extends StatelessWidget {
  final bool isArabic;
  final _LoginPalette palette;
  final VoidCallback onTap;

  const _SignUpLine({
    required this.isArabic,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _LoginCopy.of(isArabic);

    return Column(
      children: [
        Container(
          height: 1.2,
          color: palette.signUpLine,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Text(
              copy.signUpLead,
              style: TextStyle(
                fontFamily: _pageFontFamily(isArabic),
                fontSize: 16,
                color: palette.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  copy.signUpAction,
                  style: TextStyle(
                    fontFamily: _pageFontFamily(isArabic),
                    fontSize: 16,
                    color: palette.linkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureFooter extends StatelessWidget {
  final bool isArabic;
  final bool isCompact;
  final _LoginPalette palette;

  const _FeatureFooter({
    required this.isArabic,
    required this.isCompact,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _LoginCopy.of(isArabic);
    final items = [
      _FeatureItemData(
        icon: Icons.verified_user_rounded,
        label: copy.featureSafety,
        color: const Color(0xFF1C8BFF),
        glow: palette.featureBlueGlow,
        underline: palette.featureBlueLine,
      ),
      _FeatureItemData(
        icon: Icons.notifications_active_rounded,
        label: copy.featureAlerts,
        color: const Color(0xFFFFC400),
        glow: palette.featureYellowGlow,
        underline: palette.featureYellowLine,
      ),
      _FeatureItemData(
        icon: Icons.groups_rounded,
        label: copy.featureWorkers,
        color: const Color(0xFF1B7BFF),
        glow: palette.featureBlueGlow,
        underline: palette.featureBlueLine,
      ),
    ];
    final orderedItems = isArabic ? items.reversed.toList() : items;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 18,
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 22 : 26),
            color: palette.footerBackground,
            border: Border.all(color: palette.footerBorder),
            boxShadow: [
              BoxShadow(
                color: palette.softShadow,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: List.generate(orderedItems.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Container(
                  width: 1,
                  height: isCompact ? 92 : 102,
                  color: palette.footerDivider,
                );
              }

              final item = orderedItems[index ~/ 2];
              return Expanded(
                child: _FeatureTile(
                  data: item,
                  isArabic: isArabic,
                  isCompact: isCompact,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _FeatureItemData data;
  final bool isArabic;
  final bool isCompact;

  const _FeatureTile({
    required this.data,
    required this.isArabic,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 6 : 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 48 : 56,
            height: isCompact ? 48 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.glow,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: isCompact ? 36 : 42,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _pageFontFamily(isArabic),
              fontSize: isCompact ? 15 : 17,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1C306F),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Container(
            width: isCompact ? 52 : 60,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: data.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterCaption extends StatelessWidget {
  final bool isDark;
  final bool isArabic;

  const _FooterCaption({
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _LoginCopy.of(isArabic);
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF506080);

    return Column(
      children: [
        Text(
          copy.copyright,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.projectName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textColor.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

class _DecorativeRule extends StatelessWidget {
  final _LoginPalette palette;
  final double width;

  const _DecorativeRule({
    required this.palette,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: [
            palette.ruleFade,
            palette.ruleActive,
            palette.ruleFade,
          ],
        ),
      ),
    );
  }
}

class _GlowingLogo extends StatelessWidget {
  final bool isCompact;
  final bool isWeb;
  final _LoginPalette palette;

  const _GlowingLogo({
    required this.isCompact,
    required this.isWeb,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isCompact
        ? 240
        : isWeb
            ? 278
            : 292;
    const logoAsset = 'assets/images/logo_shield_flood.png';
    final isLight = palette.pageBackground.computeLuminance() > 0.5;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.logoAuraCenter,
                  palette.logoAuraOuter,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.logoAuraShadow,
                  blurRadius: 72,
                  spreadRadius: 22,
                ),
                BoxShadow(
                  color: palette.logoAuraShadow.withValues(alpha: 0.35),
                  blurRadius: 116,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: isLight ? 0.2 : 0.18,
                  ),
                  blurRadius: 34,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          SizedBox(
            width: isCompact
                ? 232
                : isWeb
                    ? 252
                    : 268,
            height: isCompact
                ? 232
                : isWeb
                    ? 252
                    : 268,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isLight ? 0.14 : 0.26,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Image.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  color: isLight ? Colors.white.withValues(alpha: 0.02) : null,
                  colorBlendMode: isLight ? BlendMode.plus : BlendMode.srcOver,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroWorkersOverlay extends StatelessWidget {
  final bool isCompact;
  final bool isDark;

  const _HeroWorkersOverlay({
    required this.isCompact,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final assetName = isDark
        ? 'assets/images/workers_login_dark_hero.png'
        : 'assets/images/workers_login_light_hero.png';
    final width = isCompact ? 488.0 : 778.0;
    final height = isCompact ? 278.0 : 372.0;
    final veilColor = isDark ? const Color(0xFF07112C) : Colors.white;
    final hazeColor =
        isDark ? const Color(0xFF1E73FF) : const Color(0xFFB8DEFF);
    final imageOpacity = isDark ? 0.9 : 0.9;
    final blurOpacity = isDark ? 0.34 : 0.14;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.98),
                Colors.white,
                Colors.white.withValues(alpha: 0.94),
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.22),
                Colors.transparent,
              ],
              stops: const [0.0, 0.16, 0.42, 0.66, 0.86, 1.0],
            ).createShader(bounds),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: blurOpacity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Image.asset(
                      assetName,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.14),
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.12, 0.24, 0.88, 1.0],
                  ).createShader(bounds),
                  child: Opacity(
                    opacity: imageOpacity,
                    child: Image.asset(
                      assetName,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.14),
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.38),
                radius: 0.94,
                colors: [
                  hazeColor.withValues(alpha: isDark ? 0.36 : 0.16),
                  hazeColor.withValues(alpha: isDark ? 0.16 : 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.32, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  veilColor.withValues(alpha: isDark ? 0.04 : 0.0),
                  veilColor.withValues(alpha: isDark ? 0.12 : 0.025),
                  veilColor.withValues(alpha: isDark ? 0.42 : 0.14),
                ],
                stops: const [0.0, 0.46, 0.74, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  veilColor.withValues(alpha: isDark ? 0.14 : 0.05),
                  Colors.transparent,
                  Colors.transparent,
                  veilColor.withValues(alpha: isDark ? 0.14 : 0.05),
                ],
                stops: const [0.0, 0.14, 0.86, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final List<Color> selectedGradient;
  final Color selectedBorderColor;
  final Color selectedShadow;
  final Color textColor;
  final Color selectedTextColor;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.selectedGradient,
    required this.selectedBorderColor,
    required this.selectedShadow,
    required this.textColor,
    required this.selectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: selected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: selectedGradient,
              )
            : null,
        border: Border.all(
          color: selected ? selectedBorderColor : Colors.transparent,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: selectedShadow,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? selectedTextColor : textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSegmentChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final List<Color> selectedGradient;
  final Color selectedBorderColor;
  final Color selectedShadow;
  final Color iconColor;
  final Color selectedIconColor;
  final VoidCallback onTap;

  const _IconSegmentChip({
    required this.icon,
    required this.selected,
    required this.selectedGradient,
    required this.selectedBorderColor,
    required this.selectedShadow,
    required this.iconColor,
    required this.selectedIconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: selected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: selectedGradient,
              )
            : null,
        border: Border.all(
          color: selected ? selectedBorderColor : Colors.transparent,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: selectedShadow,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            icon,
            size: 24,
            color: selected ? selectedIconColor : iconColor,
          ),
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final IconData icon;

  const _ActionBadge({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}

class _ActionArrow extends StatelessWidget {
  final bool isArabic;

  const _ActionArrow({
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 22,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool isDark;

  const _SignalPainter({
    required this.color,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.17);
    final baseRadius = math.min(size.width * 0.19, 152.0);
    final horizontalPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.13 : 0.07)
      ..strokeWidth = 1.0;
    final verticalPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.13 : 0.07)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - baseRadius * 1.18, center.dy),
      Offset(center.dx + baseRadius * 1.18, center.dy),
      horizontalPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - baseRadius * 0.9),
      Offset(center.dx, center.dy + baseRadius * 0.92),
      verticalPaint,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: isDark ? 0.13 : 0.08);

    final circleRadii = [
      baseRadius * 0.58,
      baseRadius * 0.8,
      baseRadius * 1.02,
    ];
    for (final radius in circleRadii) {
      canvas.drawCircle(center, radius, ringPaint);
    }

    final arcRadii = [baseRadius * 1.18, baseRadius * 1.34];
    for (final radius in arcRadii) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, math.pi * 1.04, math.pi * 0.92, false, ringPaint);
      canvas.drawArc(rect, -math.pi * 0.96, math.pi * 0.92, false, ringPaint);
    }

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: isDark ? 0.56 : 0.3);
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi * 0.82 + (i / 11) * (math.pi * 1.64);
      final dx = center.dx + baseRadius * 1.34 * math.cos(angle);
      final dy = center.dy + baseRadius * 1.34 * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) {
    return color != oldDelegate.color ||
        accent != oldDelegate.accent ||
        isDark != oldDelegate.isDark;
  }
}

class _AtmospherePainter extends CustomPainter {
  final _LoginPalette palette;
  final bool isDark;

  const _AtmospherePainter({
    required this.palette,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bottomLeft = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.cornerGlow,
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.95),
          radius: size.width * 0.26,
        ),
      );

    final bottomRight = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.cornerGlow,
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.92, size.height * 0.95),
          radius: size.width * 0.26,
        ),
      );

    canvas.drawRect(Offset.zero & size, bottomLeft);
    canvas.drawRect(Offset.zero & size, bottomRight);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = palette.noiseDot.withValues(alpha: isDark ? 0.55 : 0.4);
    for (int i = 0; i < 44; i++) {
      final dx = size.width * (0.04 + (i % 11) * 0.085);
      final dy = size.height * (0.86 + (i ~/ 11) * 0.03);
      canvas.drawCircle(Offset(dx, dy), 1.15 + (i % 3) * 0.28, dotPaint);
    }

    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          palette.sceneHaze,
          palette.sceneHaze.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRect(Offset.zero & size, hazePaint);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return palette != oldDelegate.palette || isDark != oldDelegate.isDark;
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required _LoginPalette palette,
  required bool isArabic,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontFamily: _pageFontFamily(isArabic),
      fontSize: 16,
      color: palette.hintText,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: palette.inputBackground,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 18,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : IconTheme(
            data: IconThemeData(color: palette.fieldIcon, size: 26),
            child: prefixIcon,
          ),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: palette.inputBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: palette.inputFocusBorder,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: palette.errorText,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: palette.errorText,
        width: 1.5,
      ),
    ),
  );
}

String _pageFontFamily(bool isArabic) => isArabic ? 'Roboto' : 'Inter';

class _LanguageItem {
  final String code;
  final bool isArabic;

  const _LanguageItem({
    required this.code,
    required this.isArabic,
  });
}

class _FeatureItemData {
  final IconData icon;
  final String label;
  final Color color;
  final Color glow;
  final Color underline;

  const _FeatureItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.glow,
    required this.underline,
  });
}

class _LoginCopy {
  final String projectName;
  final String titleFirstPart;
  final String titleSecondPart;
  final String subtitle;
  final String emailLabel;
  final String emailHint;
  final String passwordLabel;
  final String passwordHint;
  final String rememberMe;
  final String forgotPassword;
  final String loginButton;
  final String orContinueWith;
  final String googleButton;
  final String signUpLead;
  final String signUpAction;
  final String featureSafety;
  final String featureAlerts;
  final String featureWorkers;
  final String copyright;

  const _LoginCopy({
    required this.projectName,
    required this.titleFirstPart,
    required this.titleSecondPart,
    required this.subtitle,
    required this.emailLabel,
    required this.emailHint,
    required this.passwordLabel,
    required this.passwordHint,
    required this.rememberMe,
    required this.forgotPassword,
    required this.loginButton,
    required this.orContinueWith,
    required this.googleButton,
    required this.signUpLead,
    required this.signUpAction,
    required this.featureSafety,
    required this.featureAlerts,
    required this.featureWorkers,
    required this.copyright,
  });

  static _LoginCopy of(bool isArabic) {
    if (isArabic) {
      return const _LoginCopy(
        projectName: 'Smooth Monitoring and Fortification',
        titleFirstPart: 'مرحباً',
        titleSecondPart: 'بعودتك',
        subtitle: 'الأمان الذي يمكنك الاعتماد عليه',
        emailLabel: 'البريد الإلكتروني',
        emailHint: 'أدخل بريدك الإلكتروني',
        passwordLabel: 'كلمة المرور',
        passwordHint: 'أدخل كلمة المرور',
        rememberMe: 'تذكرني',
        forgotPassword: 'هل نسيت كلمة المرور؟',
        loginButton: 'تسجيل الدخول الآمن',
        orContinueWith: 'أو أكمل باستخدام',
        googleButton: 'المتابعة باستخدام Google',
        signUpLead: 'ليس لديك حساب؟',
        signUpAction: 'إنشاء حساب',
        featureSafety: 'السلامة أولاً',
        featureAlerts: 'تنبيهات فورية',
        featureWorkers: 'حماية العمال',
        copyright: '© 2025 SMF',
      );
    }

    return const _LoginCopy(
      projectName: 'Smooth Monitoring and Fortification',
      titleFirstPart: 'Welcome',
      titleSecondPart: 'Back',
      subtitle: 'Security You Can Rely On',
      emailLabel: 'Email Address',
      emailHint: 'Enter your email',
      passwordLabel: 'Password',
      passwordHint: 'Enter your password',
      rememberMe: 'Remember me',
      forgotPassword: 'Forgot Password?',
      loginButton: 'Secure Login',
      orContinueWith: 'Or continue with',
      googleButton: 'Continue with Google',
      signUpLead: 'Don’t have an account?',
      signUpAction: 'Sign up',
      featureSafety: 'Safety First',
      featureAlerts: 'Real-time Alerts',
      featureWorkers: 'Protecting Workers',
      copyright: '© 2025 SMF',
    );
  }
}

class _LoginPalette {
  final Color pageBackground;
  final List<Color> pageGradient;
  final List<Color> frameGradient;
  final Color frameBorder;
  final Color outerGlow;
  final List<Color> headerAura;
  final Color signalColor;
  final Color signalAccent;
  final Color cornerGlow;
  final Color skyline;
  final Color sceneHaze;
  final Color noiseDot;
  final Color toggleBackground;
  final Color toggleBorder;
  final Color softShadow;
  final Color segmentText;
  final Color segmentSelectedBorder;
  final Color segmentGlow;
  final List<Color> themeLightGradient;
  final Color themeLightIcon;
  final Color themeInactiveIcon;
  final Color titlePrimary;
  final Color titleAccent;
  final Color subtitleColor;
  final Color projectNameColor;
  final Color ruleActive;
  final Color ruleFade;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color emailBubble;
  final Color emailBubbleGlow;
  final Color passwordBubble;
  final Color passwordBubbleGlow;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color inputText;
  final Color hintText;
  final Color fieldIcon;
  final Color errorText;
  final Color secondaryText;
  final Color linkAccent;
  final List<Color> primaryButtonGradient;
  final Color primaryButtonBorder;
  final Color primaryButtonGlow;
  final Color checkFill;
  final Color checkBorder;
  final Color checkGlow;
  final Color dividerFade;
  final Color dividerActive;
  final Color dividerDot;
  final Color dividerGlow;
  final Color googleButtonBackground;
  final Color googleButtonBorder;
  final Color googleButtonText;
  final Color signUpLine;
  final Color linkPrimary;
  final Color footerBackground;
  final Color footerBorder;
  final Color footerDivider;
  final Color featureBlueGlow;
  final Color featureYellowGlow;
  final Color featureBlueLine;
  final Color featureYellowLine;
  final Color logoAuraCenter;
  final Color logoAuraOuter;
  final Color logoAuraShadow;

  const _LoginPalette({
    required this.pageBackground,
    required this.pageGradient,
    required this.frameGradient,
    required this.frameBorder,
    required this.outerGlow,
    required this.headerAura,
    required this.signalColor,
    required this.signalAccent,
    required this.cornerGlow,
    required this.skyline,
    required this.sceneHaze,
    required this.noiseDot,
    required this.toggleBackground,
    required this.toggleBorder,
    required this.softShadow,
    required this.segmentText,
    required this.segmentSelectedBorder,
    required this.segmentGlow,
    required this.themeLightGradient,
    required this.themeLightIcon,
    required this.themeInactiveIcon,
    required this.titlePrimary,
    required this.titleAccent,
    required this.subtitleColor,
    required this.projectNameColor,
    required this.ruleActive,
    required this.ruleFade,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.emailBubble,
    required this.emailBubbleGlow,
    required this.passwordBubble,
    required this.passwordBubbleGlow,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.inputText,
    required this.hintText,
    required this.fieldIcon,
    required this.errorText,
    required this.secondaryText,
    required this.linkAccent,
    required this.primaryButtonGradient,
    required this.primaryButtonBorder,
    required this.primaryButtonGlow,
    required this.checkFill,
    required this.checkBorder,
    required this.checkGlow,
    required this.dividerFade,
    required this.dividerActive,
    required this.dividerDot,
    required this.dividerGlow,
    required this.googleButtonBackground,
    required this.googleButtonBorder,
    required this.googleButtonText,
    required this.signUpLine,
    required this.linkPrimary,
    required this.footerBackground,
    required this.footerBorder,
    required this.footerDivider,
    required this.featureBlueGlow,
    required this.featureYellowGlow,
    required this.featureBlueLine,
    required this.featureYellowLine,
    required this.logoAuraCenter,
    required this.logoAuraOuter,
    required this.logoAuraShadow,
  });

  factory _LoginPalette.resolve({required bool isDark}) {
    if (isDark) {
      return const _LoginPalette(
        pageBackground: Color(0xFF040B1F),
        pageGradient: [
          Color(0xFF040B1F),
          Color(0xFF061033),
          Color(0xFF040818),
        ],
        frameGradient: [
          Color(0xFF07112C),
          Color(0xFF091534),
          Color(0xFF060C22),
        ],
        frameBorder: Color(0xFF708CFF),
        outerGlow: Color(0x332B63FF),
        headerAura: [
          Color(0x331463FF),
          Color(0x140C1E56),
          Color(0x00000000),
        ],
        signalColor: Color(0x6647A4FF),
        signalAccent: Color(0xFF32C5FF),
        cornerGlow: Color(0x552460FF),
        skyline: Color(0xFF72A9FF),
        sceneHaze: Color(0x141D63FF),
        noiseDot: Color(0xFF46A3FF),
        toggleBackground: Color(0xCC091127),
        toggleBorder: Color(0x80B9CCFF),
        softShadow: Color(0x33000000),
        segmentText: Color(0xFFF4F7FF),
        segmentSelectedBorder: Color(0xCCFFFFFF),
        segmentGlow: Color(0x552A5FFF),
        themeLightGradient: [
          Color(0xFFFEF7DA),
          Color(0xFFFFFFFF),
        ],
        themeLightIcon: Color(0xFFF3B400),
        themeInactiveIcon: Color(0xFFE8EDF8),
        titlePrimary: Colors.white,
        titleAccent: Color(0xFFFFC400),
        subtitleColor: Color(0xFFF4F7FF),
        projectNameColor: Color(0xFFF5F6FB),
        ruleActive: Color(0xFFFFC400),
        ruleFade: Color(0x00FFC400),
        cardBackground: Color(0xD0091534),
        cardBorder: Color(0xFF8096FF),
        cardShadow: Color(0x44000000),
        emailBubble: Color(0xFF0AA4FF),
        emailBubbleGlow: Color(0x330AA4FF),
        passwordBubble: Color(0xFFFFC400),
        passwordBubbleGlow: Color(0x33FFC400),
        inputBackground: Color(0x1AFFFFFF),
        inputBorder: Color(0x66A0B4E8),
        inputFocusBorder: Color(0xFF57B0FF),
        inputText: Colors.white,
        hintText: Color(0xB3D7E2FF),
        fieldIcon: Color(0xFFBDC7E6),
        errorText: Color(0xFFFF7B7B),
        secondaryText: Color(0xFFF2F6FF),
        linkAccent: Color(0xFFFFD03A),
        primaryButtonGradient: [
          Color(0xFF0E2FE4),
          Color(0xFF12B8FF),
        ],
        primaryButtonBorder: Color(0xCC9DCCFF),
        primaryButtonGlow: Color(0x442066FF),
        checkFill: Color(0xFF1D6BFF),
        checkBorder: Color(0x80ADC4FF),
        checkGlow: Color(0x442069FF),
        dividerFade: Color(0x004DD9FF),
        dividerActive: Color(0xFF2FD2FF),
        dividerDot: Color(0xFF2FD2FF),
        dividerGlow: Color(0x772FD2FF),
        googleButtonBackground: Color(0x12FFFFFF),
        googleButtonBorder: Color(0x66A0B4E8),
        googleButtonText: Colors.white,
        signUpLine: Color(0x66A0B4E8),
        linkPrimary: Color(0xFFFFC400),
        footerBackground: Color(0xCC091127),
        footerBorder: Color(0xFF728CFF),
        footerDivider: Color(0x4D95A9D8),
        featureBlueGlow: Color(0x44187AFF),
        featureYellowGlow: Color(0x44FFC400),
        featureBlueLine: Color(0xFF266FFF),
        featureYellowLine: Color(0xFFFFC400),
        logoAuraCenter: Color(0x66398FFF),
        logoAuraOuter: Color(0x000398FF),
        logoAuraShadow: Color(0x552D72FF),
      );
    }

    return const _LoginPalette(
      pageBackground: Color(0xFFF2F7FF),
      pageGradient: [
        Color(0xFFE8F3FF),
        Color(0xFFF7FBFF),
        Color(0xFFEDF5FF),
      ],
      frameGradient: [
        Color(0xFFFFFFFF),
        Color(0xFFF8FBFF),
        Color(0xFFF1F6FF),
      ],
      frameBorder: Color(0xFFD0DEF9),
      outerGlow: Color(0x1A5A94FF),
      headerAura: [
        Color(0x2621A0FF),
        Color(0x12A4D8FF),
        Color(0x00FFFFFF),
      ],
      signalColor: Color(0x3345A4FF),
      signalAccent: Color(0xFF33C1F5),
      cornerGlow: Color(0x263A8BFF),
      skyline: Color(0xFF6FA9F2),
      sceneHaze: Color(0x110A7FFF),
      noiseDot: Color(0xFF247BE6),
      toggleBackground: Color(0xF7FFFFFF),
      toggleBorder: Color(0xFFD8E4F8),
      softShadow: Color(0x16073B78),
      segmentText: Color(0xFF1E306A),
      segmentSelectedBorder: Color(0x99FFFFFF),
      segmentGlow: Color(0x26296BFF),
      themeLightGradient: [
        Color(0xFFFFF1B3),
        Color(0xFFFFFFFF),
      ],
      themeLightIcon: Color(0xFFF3B400),
      themeInactiveIcon: Color(0xFF6877A0),
      titlePrimary: Color(0xFF1738A8),
      titleAccent: Color(0xFFFFC400),
      subtitleColor: Color(0xFF20408E),
      projectNameColor: Color(0xFF1D2B55),
      ruleActive: Color(0xFFFFC400),
      ruleFade: Color(0x00FFC400),
      cardBackground: Color(0xF8FFFFFF),
      cardBorder: Color(0xFFE2EAF9),
      cardShadow: Color(0x16073B78),
      emailBubble: Color(0xFF0AA4FF),
      emailBubbleGlow: Color(0x220AA4FF),
      passwordBubble: Color(0xFFFFC400),
      passwordBubbleGlow: Color(0x1EFFC400),
      inputBackground: Color(0xFFFFFFFF),
      inputBorder: Color(0xFFDDE5F4),
      inputFocusBorder: Color(0xFF3E8CFF),
      inputText: Color(0xFF213664),
      hintText: Color(0xFF97A2BF),
      fieldIcon: Color(0xFF8A96B3),
      errorText: Color(0xFFD84C4C),
      secondaryText: Color(0xFF1F316A),
      linkAccent: Color(0xFFD6A100),
      primaryButtonGradient: [
        Color(0xFF1042F1),
        Color(0xFF17BBFF),
      ],
      primaryButtonBorder: Color(0xFF9DD0FF),
      primaryButtonGlow: Color(0x22175EFF),
      checkFill: Color(0xFF1D6BFF),
      checkBorder: Color(0xFFB7C7E9),
      checkGlow: Color(0x221D6BFF),
      dividerFade: Color(0x0036B9FF),
      dividerActive: Color(0xFF54BEFF),
      dividerDot: Color(0xFF54BEFF),
      dividerGlow: Color(0x3354BEFF),
      googleButtonBackground: Color(0xFFFFFFFF),
      googleButtonBorder: Color(0xFFDCE5F6),
      googleButtonText: Color(0xFF143592),
      signUpLine: Color(0xFFD7E1F4),
      linkPrimary: Color(0xFF1653E5),
      footerBackground: Color(0xF8FFFFFF),
      footerBorder: Color(0xFFE1EAFB),
      footerDivider: Color(0xFFD5E0F4),
      featureBlueGlow: Color(0x22187AFF),
      featureYellowGlow: Color(0x22FFC400),
      featureBlueLine: Color(0xFF266FFF),
      featureYellowLine: Color(0xFFFFC400),
      logoAuraCenter: Color(0x33398FFF),
      logoAuraOuter: Color(0x000398FF),
      logoAuraShadow: Color(0x1A2D72FF),
    );
  }
}
