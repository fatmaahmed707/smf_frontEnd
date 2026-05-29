import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? const [
                    Color(0xFF0A1128),
                    Color(0xFF1A1F3A),
                    Color(0xFF0F1535),
                    Color(0xFF1E2A4A),
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFE5E7EB),
                    Color(0xFFD1D5DB),
                    Color(0xFFF3F4F6),
                  ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 0 : 24.0,
                    vertical: 40.0,
                  ),
                  child: Container(
                    constraints:
                        BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
                    child: _emailSent
                        ? _buildSuccessView(themeProvider.isDarkMode)
                        : _buildResetForm(themeProvider.isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(isDarkMode),
        const SizedBox(height: 32),
        _buildTitle(isDarkMode),
        const SizedBox(height: 16),
        _buildDescription(isDarkMode),
        const SizedBox(height: 40),
        _buildResetCard(isDarkMode),
      ],
    );
  }

  Widget _buildSuccessView(bool isDarkMode) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9FF)
                        .withValues(alpha: 0.4 + _glowController.value * 0.3),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: Color(0xFF00D9FF),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: Text(
            lang.getText('checkYourEmail'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          lang.getText('resetEmailSent'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              lang.getText('backToLogin'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _handleResetPassword,
          child: Text(
            lang.getText('resendEmail'),
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB)
                    .withValues(alpha: 0.4 + _glowController.value * 0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 50,
            color: Color(0xFF2563EB),
          ),
        );
      },
    );
  }

  Widget _buildTitle(bool isDarkMode) {
    final lang = context.watch<LanguageProvider>();
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
      ).createShader(bounds),
      child: Text(
        lang.getText('forgotPasswordTitle'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescription(bool isDarkMode) {
    final lang = context.watch<LanguageProvider>();
    return Text(
      lang.getText('forgotPasswordSubtitle'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.6),
        fontSize: 15,
        height: 1.5,
      ),
    );
  }

  Widget _buildResetCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.5),
                      ],
              ),
            ),
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEmailField(isDarkMode),
                  const SizedBox(height: 32),
                  _buildResetButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(bool isDarkMode) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.3),
                ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: lang.getText('emailHint'),
          hintStyle: TextStyle(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return lang.getText('emailRequired');
          if (!value.contains('@')) return lang.getText('emailInvalid');
          return null;
        },
      ),
    );
  }

  Widget _buildResetButton() {
    final lang = context.watch<LanguageProvider>();
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                lang.getText('sendResetLink'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
