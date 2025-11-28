// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bodytalk_app/pages/login_page.dart';
import 'package:bodytalk_app/services/api_service.dart';
import 'package:bodytalk_app/main.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _bg = Color(0xFF020617);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFFF9800);

  bool _notifEnabled = true;
  bool _darkMode = true;
  bool _autoSyncPlan = false;
  String _language = 'العربية';
  String _gender = 'غير محدد';
  int? _age;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSyncPlan = prefs.getBool('auto_sync_plan') ?? false;
    });
  }

  // ======================
  //  تسجيل الخروج وحذف الحساب
  // ======================

  Future<void> _logout() async {
    // مسح توكن السيرفر الحقيقي
    await ApiService.logout();
    // مسح أي بيانات قديمة إضافية
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccountLocal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف الحساب من هذا الجهاز"),
        content: const Text(
          "سيتم حذف بيانات حسابك المخزّنة على هذا الجهاز فقط.\n"
          "يمكنك لاحقًا تسجيل الدخول أو إنشاء حساب جديد.\n\n"
          "هل تريد المتابعة؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // مسح كل البيانات المحلية

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ======================
  //   دوال مساعدة للإشعارات والاختيارات
  // ======================

  void _showSoonSnack([String? msg]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg ?? 'سيتم تفعيل هذه الميزة في التحديثات القادمة ✨',
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<void> _pickGender() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Select gender',
                    fr: 'Sélectionnez le genre',
                    ar: 'اختر الجنس',
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'ذكر'),
                  title:
                      const Text('ذكر', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.male, color: Colors.white70),
                ),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'أنثى'),
                  title:
                      const Text('أنثى', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.female, color: Colors.white70),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _gender = result);
      _showSoonSnack('سيتم استخدام الجنس مستقبلاً لتحسين دقة التحليل 💡');
    }
  }

  Future<void> _pickLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Select app language',
                    fr: "Sélectionnez la langue de l'application",
                    ar: 'اختر لغة التطبيق',
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'العربية'),
                  title: const Text('العربية',
                      style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.language, color: Colors.white70),
                ),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'English'),
                  title: const Text('English',
                      style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.language, color: Colors.white70),
                ),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'Français'),
                  title: const Text('Français',
                      style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.language, color: Colors.white70),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _language = result);
      final prefs = await SharedPreferences.getInstance();
      final code = (result == 'العربية')
          ? 'ar'
          : (result == 'Français')
              ? 'fr'
              : 'en';
      await prefs.setString('app_language', code);
      // تطبيق اللغة فوراً بدون إعادة تشغيل
      BodyTalkApp.of(context)?.setLocale(code);
      _showSoonSnack('Language changed.');
    }
  }

  Future<void> _pickAge() async {
    int tempAge = _age ?? 25;

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'اختر عمرك التقريبي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$tempAge سنة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: tempAge.toDouble(),
                      min: 10,
                      max: 80,
                      divisions: 70,
                      activeColor: _orange,
                      inactiveColor: Colors.white.withValues(alpha: 0.2),
                      onChanged: (v) {
                        setModalState(() => tempAge = v.toInt());
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, tempAge),
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _age = result);
      _showSoonSnack('سيتم استخدام العمر لتحسين فهم وضعك الصحي العام 🧠');
    }
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ageLabel = _age != null ? '$_age سنة' : 'غير محدد';

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الملف الشخصي والإعدادات',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كرت العنوان
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [_blue, _orange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'حسابك في BodyTalk AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'إصدار تجريبي',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 20),

                // 🧍‍♂️ المعلومات الشخصية
                _sectionCard(
                  icon: Icons.badge_outlined,
                  title: 'المعلومات الشخصية',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'الاسم',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'اسم المستخدم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.white70, size: 18),
                          onPressed: () => _showSoonSnack(
                              'سيتم دعم تعديل الاسم من هنا لاحقًا ✏️'),
                        ),
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'البريد الإلكتروني',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'user@example.com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.white70, size: 18),
                          onPressed: () => _showSoonSnack(
                              'سيتم دعم تغيير البريد الإلكتروني من هنا 📧'),
                        ),
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickGender,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الجنس',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _gender,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickAge,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'العمر التقريبي',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ageLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showSoonSnack(
                                'سيتم الاعتماد على الجنس/العمر بشكل أكبر في التحليل قريبًا 💡'),
                            icon: const Icon(Icons.info_outline,
                                size: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🔐 إدارة الحساب
                _sectionCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'إدارة الحساب',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.lock_reset, color: Colors.white70),
                        title: const Text(
                          'تغيير كلمة المرور',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'يمكنك لاحقًا إعادة ضبط كلمة المرور من هنا.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _showSoonSnack(
                            'تغيير كلمة المرور سيتوفر في النسخة المتقدمة 🔐'),
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.alternate_email,
                            color: Colors.white70),
                        title: const Text(
                          'تغيير البريد الإلكتروني',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'تعديل البريد المرتبط بالحساب سيتم دعمه لاحقًا.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _showSoonSnack(
                            'تغيير البريد الإلكتروني سيتوفر مستقبلًا 📨'),
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      // زر تسجيل الخروج
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout,
                            color: Colors.orangeAccent),
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'إغلاق جلستك الحالية والعودة لصفحة تسجيل الدخول.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        onTap: _logout,
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      // زر حذف الحساب من الجهاز
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_forever,
                            color: Colors.redAccent),
                        title: const Text(
                          'حذف الحساب من هذا الجهاز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'سيتم حذف بيانات التطبيق المخزّنة على هذا الجهاز فقط.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        onTap: _deleteAccountLocal,
                      ),
                    ],
                  ),
                ),

                // ⚙️ إعدادات التطبيق
                _sectionCard(
                  icon: Icons.settings_suggest_outlined,
                  title: 'إعدادات التطبيق',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _orange,
                        inactiveThumbColor: Colors.grey.shade500,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.12),
                        title: const Text(
                          'تفعيل الإشعارات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'تنبيهات خفيفة لتذكيرك بالتحليل والمتابعة.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        value: _notifEnabled,
                        onChanged: (v) {
                          setState(() => _notifEnabled = v);
                          _showSoonSnack(
                              'سيتم ربط الإشعارات مع خطط المتابعة اليومية لاحقًا 🔔');
                        },
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _orange,
                        inactiveThumbColor: Colors.grey.shade500,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.12),
                        title: const Text(
                          'الوضع الداكن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'الوضع الحالي: داكن، ويمكن إضافة وضع فاتح لاحقًا.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        value: _darkMode,
                        onChanged: (v) {
                          setState(() => _darkMode = v);
                          _showSoonSnack(
                              'دعم أوضاع ألوان متعددة سيتم لاحقًا 🎨');
                        },
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _orange,
                        inactiveThumbColor: Colors.grey.shade500,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.12),
                        title: const Text(
                          'مزامنة الخطط تلقائيًا',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          'عند التفعيل: تُربط خطة الوجبات بخطة التمارين تلقائيًا.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        value: _autoSyncPlan,
                        onChanged: (v) async {
                          setState(() => _autoSyncPlan = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('auto_sync_plan', v);
                          _showSoonSnack(v
                              ? 'تم تفعيل المزامنة التلقائية بين الخطط ✅'
                              : 'تم إيقاف المزامنة التلقائية بين الخطط');
                        },
                      ),
                    ],
                  ),
                ),

                _sectionCard(
                  icon: Icons.language,
                  title: 'اللغة',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'اللغة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _language,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white70),
                          onPressed: _pickLanguage,
                        ),
                      ),
                    ],
                  ),
                ),

                // 💳 الاشتراك والتجربة المجانية
                _sectionCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'الاشتراك والتجربة المجانية',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الوضع الحالي:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green.withValues(alpha: 0.18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'نسخة تجريبية مع خطط اشتراك مستقبلية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'في النسخ القادمة يمكن تفعيل تجربة مجانية (مثلاً 3 أيام)، ثم '
                        'الاشتراك الشهري أو السنوي عبر طرق دفع مثل Apple Pay و Google Pay، '
                        'للوصول إلى تحليلات أعمق وخطط مخصصة أكثر.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showSoonSnack(
                              'إدارة الاشتراك ستُفعَّل عند ربط التطبيق ببوابة دفع 🔑'),
                          icon:
                              const Icon(Icons.credit_card_outlined, size: 18),
                          label: const Text(
                            'إدارة الاشتراك (قريبًا)',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ℹ️ حول التطبيق
                _sectionCard(
                  icon: Icons.info_outline,
                  title: 'حول التطبيق',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BodyTalk AI – مساعدك نحو حياة صحية أذكى',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'يهدف BodyTalk AI إلى مساعدتك على فهم وضعك الصحي بشكل أبسط، '
                        'من خلال تحليل صور جسمك ووجباتك، وتقديم ملاحظات ونصائح تساعدك '
                        'على تحسين نمط حياتك، متابعة تقدمك، واتخاذ قرارات صحية أفضل خطوة بخطوة.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'التطبيق ليس بديلاً عن استشارة الطبيب أو الأخصائي، '
                        'لكنه أداة داعمة تمنحك رؤية أوضح عن جسمك وعاداتك الغذائية.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _showSoonSnack(
                                'سيتم إضافة صفحة سياسة الخصوصية لاحقًا 📃'),
                            child: const Text(
                              'سياسة الخصوصية',
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => _showSoonSnack(
                                'سيتم إضافة الشروط والأحكام في إصدار قادم 📜'),
                            child: const Text(
                              'الشروط والأحكام',
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'v0.1.0',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'يمكن ربط هذه الإعدادات لاحقًا بحساب حقيقي وسيرفر ونسخة مدفوعة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 80.ms)
                    .slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
