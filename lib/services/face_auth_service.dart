// lib/services/face_auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class FaceAuthService {
  static final FaceAuthService instance = FaceAuthService();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometrics (Face ID / Fingerprint)
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('❌ Biometric check error: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('❌ Get available biometrics error: $e');
      return [];
    }
  }

  /// Check if Face ID is available (iOS)
  Future<bool> isFaceIdAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if Fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak);
  }

  /// Authenticate using biometrics with proper error handling
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      // Check if biometrics are available
      final canAuthenticate = await canCheckBiometrics();
      if (!canAuthenticate) {
        debugPrint('⚠️ Biometrics not available on this device');
        return false;
      }

      // Attempt authentication
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'Verify your identity to continue',
      );

      if (didAuthenticate) {
        debugPrint('✅ Biometric authentication successful');
      } else {
        debugPrint('⚠️ Biometric authentication failed');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(
          '❌ Platform Exception during biometric auth: ${e.code} - ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
        case 'notAvailable':
          debugPrint('❌ Biometric authentication not available');
          break;
        case 'NotEnrolled':
        case 'notEnrolled':
          debugPrint('❌ No biometrics enrolled on device');
          break;
        case 'PasscodeNotSet':
        case 'passcodeNotSet':
          debugPrint('❌ Passcode not set on device');
          break;
        case 'LockedOut':
        case 'lockedOut':
        case 'locked_out':
          debugPrint('❌ Too many failed attempts, locked out');
          break;
        case 'PermanentlyLockedOut':
        case 'permanentlyLockedOut':
          debugPrint('❌ Biometrics permanently locked out');
          break;
        default:
          debugPrint('❌ Unhandled error code: ${e.code}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Unexpected biometric auth error: $e');
      return false;
    }
  }

  /// Simplified authenticate method for backward compatibility
  Future<bool> authenticate({String? reason}) {
    return authenticateWithBiometrics(reason: reason);
  }

  /// Stop authentication (cancel)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      debugPrint('🛑 Biometric authentication stopped');
    } catch (e) {
      debugPrint('❌ Error stopping authentication: $e');
    }
  }
}
