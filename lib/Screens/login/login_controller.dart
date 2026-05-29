import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => true;
  String? get errorMessage => _errorMessage;

  Future<bool> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.instance.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error, stackTrace) {
      debugPrint('Login real error: $error');
      debugPrint('Login stack trace: $stackTrace');

      _errorMessage = 'Login failed: $error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await GoogleAuthService.instance.signIn();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error, stackTrace) {
      debugPrint('🔥 Google Sign-In ERROR: $error');
      debugPrint('🔥 Google Sign-In STACK TRACE: $stackTrace');

      _errorMessage = 'Google sign-in failed: $error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
