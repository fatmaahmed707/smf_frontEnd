import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../models/auth_session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class GoogleWebSignInButton extends StatefulWidget {
  final Future<void> Function(AuthSession session) onSuccess;
  final void Function(String message) onError;

  const GoogleWebSignInButton({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _subscription;
  bool _isHandling = false;

  @override
  void initState() {
    super.initState();

    _googleSignIn = GoogleSignIn(
      scopes: const ['openid', 'email', 'profile'],
      clientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
    );

    debugPrint('Google Web Client ID used: $_googleWebClientId');

    _subscription = _googleSignIn.onCurrentUserChanged.listen(
      _handleGoogleAccount,
      onError: (error, stackTrace) {
        debugPrint('Google Web auth stream error: $error');
        debugPrint('Google Web auth stack trace: $stackTrace');
        widget.onError('Google sign-in failed: $error');
      },
    );

    _googleSignIn.signInSilently();
  }

  Future<void> _handleGoogleAccount(GoogleSignInAccount? account) async {
    if (account == null || _isHandling) return;

    _isHandling = true;

    try {
      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Google did not return an idToken from Web button.',
        );
      }

      final session = await AuthService.instance.authenticateWithGoogleIdToken(
        idToken: idToken,
      );

      await widget.onSuccess(session);
    } catch (error, stackTrace) {
      debugPrint('Google Web login real error: $error');
      debugPrint('Google Web login stack trace: $stackTrace');
      widget.onError(error.toString());
    } finally {
      _isHandling = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: Center(
        child: web.renderButton(
          configuration: web.GSIButtonConfiguration(
            type: web.GSIButtonType.standard,
            theme: web.GSIButtonTheme.outline,
            size: web.GSIButtonSize.large,
            text: web.GSIButtonText.continueWith,
            shape: web.GSIButtonShape.rectangular,
          ),
        ),
      ),
    );
  }
}
