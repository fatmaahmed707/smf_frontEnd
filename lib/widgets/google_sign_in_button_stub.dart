import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/google_auth_service.dart';

class GoogleWebSignInButton extends StatelessWidget {
  final Future<void> Function(AuthSession session) onSuccess;
  final void Function(String message) onError;

  const GoogleWebSignInButton({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () async {
          try {
            final session = await GoogleAuthService.instance.signIn();
            await onSuccess(session);
          } catch (error) {
            onError(error.toString());
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDCE5F6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF143592),
          ),
        ),
      ),
    );
  }
}