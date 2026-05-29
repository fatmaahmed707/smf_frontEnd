import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_session.dart';
import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  static const String _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static const String _googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  static String? _emptyToNull(String value) {
    return value.isEmpty ? null : value;
  }

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['openid', 'email', 'profile'],

    // ✅ iOS فقط
    clientId: Platform.isIOS
        ? _emptyToNull(_googleIosClientId)
        : null,

    // ✅ Android هنا الصح
    serverClientId: Platform.isAndroid
        ? _emptyToNull(_googleAndroidClientId)
        : null,
  );

  Future<AuthSession> signIn() async {
    debugPrint('Is Web: $kIsWeb');
    debugPrint('Platform: $defaultTargetPlatform');
    debugPrint('Google iOS Client ID exists: ${_googleIosClientId.isNotEmpty}');
    debugPrint('Google Android Client ID exists: ${_googleAndroidClientId.isNotEmpty}');

    final account = await _googleSignIn.signIn();

    if (account == null) {
      throw const ApiException('Google sign-in was cancelled.');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;

    debugPrint('Google mobile account email: ${account.email}');
    debugPrint('Google mobile accessToken exists: ${authentication.accessToken != null}');
    debugPrint('Google mobile idToken exists: ${idToken != null}');
    debugPrint('Google mobile idToken length: ${idToken?.length ?? 0}');

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        'Google did not return an idToken on mobile.',
      );
    }

    final session = await AuthService.instance.authenticateWithGoogleIdToken(
      idToken: idToken,
    );

    debugPrint('Backend Access Token exists: ${session.accessToken.isNotEmpty}');
    debugPrint('Backend Refresh Token exists: ${session.refreshToken.isNotEmpty}');

    return session;
  }

  Future<void> disconnect() async {
    await _googleSignIn.signOut();
  }
}