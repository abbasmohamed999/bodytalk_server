// lib/services/face_auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class FaceAuthService {
  // ✅ لإتاحة الاستخدام بالشكل: FaceAuthService.instance
  static final FaceAuthService instance = FaceAuthService();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// هل الجهاز يدعم البصمة / Face ID؟
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      // يمكنك لاحقاً استبدال debugPrint بأي نظام لوجينغ
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// محاولة فتح التطبيق بالبصمة / Face ID
  Future<bool> authenticateWithBiometrics() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'قم بتأكيد هويتك باستخدام Face ID أو البصمة للمتابعة',
        // ✅ لا نمرّر options ولا useErrorDialogs ولا stickyAuth
        // لكي يكون الكود متوافق مع نسختك الحالية من local_auth
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// ✅ دالة مختصرة ليتوافق الاسم مع ما يُستدعى في LoginPage:
  /// FaceAuthService.instance.authenticate()
  Future<bool> authenticate() {
    return authenticateWithBiometrics();
  }
}
