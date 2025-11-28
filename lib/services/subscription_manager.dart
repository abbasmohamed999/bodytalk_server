import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static const _keyTrialStart = 'trial_start';
  static const _keySubscribed = 'is_subscribed';

  /// تحديد مدة التجربة المجانية (3 أيام)
  static const Duration trialDuration = Duration(days: 3);

  /// 🔹 بدء التجربة المجانية
  static Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyTrialStart)) {
      await prefs.setString(_keyTrialStart, DateTime.now().toIso8601String());
    }
  }

  /// 🔹 فحص حالة الاشتراك أو التجربة
  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();

    final subscribed = prefs.getBool(_keySubscribed) ?? false;
    if (subscribed) return true;

    final startString = prefs.getString(_keyTrialStart);
    if (startString == null) return false;

    final startDate = DateTime.parse(startString);
    final trialEnd = startDate.add(trialDuration);
    return DateTime.now().isBefore(trialEnd);
  }

  /// 🔹 إنهاء التجربة المجانية وتفعيل الاشتراك
  static Future<void> activateSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySubscribed, true);
  }

  /// 🔹 التحقق من انتهاء التجربة
  static Future<bool> isTrialExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final startString = prefs.getString(_keyTrialStart);
    if (startString == null) return false;

    final startDate = DateTime.parse(startString);
    final trialEnd = startDate.add(trialDuration);
    return DateTime.now().isAfter(trialEnd);
  }
}
