// lib/services/social_auth_service.dart

import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SocialAuthService {
  // Web Client ID from google-services.json (client_type: 3)
  static const String _webClientId =
      '629431974850-npuon8isrpd3gdefluahcv3tvvoefmbt.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: _webClientId,
  );

  /// Google Sign-In
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    debugPrint('🔑 Starting Google Sign-In...');
    try {
      // Sign out first to force account selection
      await _googleSignIn.signOut();
      debugPrint('✅ Signed out previous session');

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      debugPrint('👤 Sign-in result: ${account?.email ?? "null"}');

      if (account == null) {
        debugPrint('⚠️ User cancelled Google sign-in');
        return {'error': 'Google sign-in cancelled'};
      }

      debugPrint('✅ Account obtained: ${account.email}');
      final GoogleSignInAuthentication auth = await account.authentication;
      debugPrint('🔑 Authentication obtained');

      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      debugPrint('🎫 ID Token: ${idToken?.substring(0, 20)}...');
      debugPrint('🎫 Access Token: ${accessToken?.substring(0, 20)}...');

      if (idToken == null) {
        debugPrint('❌ No ID token received from Google');
        return {'error': 'Failed to get Google ID token'};
      }

      debugPrint('🌐 Calling backend /auth/social-login...');
      // Send to backend for verification and user creation/login
      final result = await ApiService.socialLogin(
        provider: 'google',
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        name: account.displayName ?? '',
        photoUrl: account.photoUrl,
      );

      debugPrint('📥 Backend response: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Google Sign-In Error: $e');
      debugPrint('📄 Stack: $stackTrace');
      return {'error': e.toString()};
    }
  }

  /// Apple Sign-In (iOS/macOS only)
  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!Platform.isIOS && !Platform.isMacOS) {
        return {'error': 'Apple Sign-In is only available on iOS and macOS'};
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return {'error': 'Failed to get Apple ID token'};
      }

      // Extract name
      String name = '';
      if (credential.givenName != null || credential.familyName != null) {
        name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
            .trim();
      }

      // Send to backend
      final result = await ApiService.socialLogin(
        provider: 'apple',
        idToken: idToken,
        accessToken: credential.authorizationCode,
        email: credential.email ?? '',
        name: name,
        userId: credential.userIdentifier,
      );

      return result;
    } catch (e) {
      debugPrint('❌ Apple Sign-In Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Sign out from all social providers
  static Future<void> signOutAll() async {
    try {
      await _googleSignIn.signOut();
      // Apple doesn't need explicit sign-out
    } catch (e) {
      debugPrint('❌ Sign-out Error: $e');
    }
  }
}
