// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bodytalk_app/pages/login_page.dart';
import 'package:bodytalk_app/services/api_service.dart';
import 'package:bodytalk_app/services/face_auth_service.dart';
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
  bool _biometricEnabled = false;
  String _gender = '';
  int? _age;

  // User profile data from backend
  bool _loadingProfile = true;
  String _userName = '';
  String _userEmail = '';

  // Subscription status
  bool _loadingSubscription = true;
  String _subscriptionStatus = 'free';
  String? _subscriptionType;
  DateTime? _subscriptionExpiry;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadUserProfile();
    _loadSubscriptionStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load dark mode state from app
    _darkMode = BodyTalkApp.isDarkMode(context);
  }

  /// Load user profile from backend
  Future<void> _loadUserProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _userName = data['full_name'] ?? data['name'] ?? '';
          _userEmail = data['email'] ?? '';
          // Load gender from backend
          final backendGender = data['gender'];
          if (backendGender != null && backendGender.toString().isNotEmpty) {
            _gender = backendGender.toString();
          }
          // Load age from backend
          if (data['age'] != null) {
            _age = data['age'] as int?;
          }
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  /// Edit name dialog
  Future<void> _editName() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          BodyTalkApp.tr(context,
              en: 'Edit Name', fr: 'Modifier le nom', ar: 'تعديل الاسم'),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: BodyTalkApp.tr(context,
                en: 'Enter your name', fr: 'Entrez votre nom', ar: 'أدخل اسمك'),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _orange),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              BodyTalkApp.tr(context, en: 'Cancel', fr: 'Annuler', ar: 'إلغاء'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              BodyTalkApp.tr(context, en: 'Save', fr: 'Enregistrer', ar: 'حفظ'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _userName) {
      final updated = await ApiService.updateProfile({'full_name': result});
      if (!mounted) return;
      if (updated != null) {
        setState(() => _userName = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Name updated successfully ✅',
                fr: 'Nom mis à jour avec succès ✅',
                ar: 'تم تحديث الاسم بنجاح ✅')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Failed to update name',
                fr: 'Échec de la mise à jour du nom',
                ar: 'فشل تحديث الاسم')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Edit email dialog
  Future<void> _editEmail() async {
    final controller = TextEditingController(text: _userEmail);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          BodyTalkApp.tr(context,
              en: 'Edit Email',
              fr: "Modifier l'e-mail",
              ar: 'تعديل البريد الإلكتروني'),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: BodyTalkApp.tr(context,
                en: 'Enter your email',
                fr: 'Entrez votre e-mail',
                ar: 'أدخل بريدك الإلكتروني'),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _orange),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              BodyTalkApp.tr(context, en: 'Cancel', fr: 'Annuler', ar: 'إلغاء'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              BodyTalkApp.tr(context, en: 'Save', fr: 'Enregistrer', ar: 'حفظ'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _userEmail) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(result)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Invalid email format',
                fr: 'Format d\'e-mail invalide',
                ar: 'صيغة البريد الإلكتروني غير صحيحة')),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      final updated = await ApiService.updateProfile({'email': result});
      if (!mounted) return;
      if (updated != null) {
        setState(() => _userEmail = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Email updated successfully ✅',
                fr: 'E-mail mis à jour avec succès ✅',
                ar: 'تم تحديث البريد الإلكتروني بنجاح ✅')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Failed to update email',
                fr: 'Échec de la mise à jour de l\'e-mail',
                ar: 'فشل تحديث البريد الإلكتروني')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Change password dialog - sends reset email
  Future<void> _showChangePasswordDialog() async {
    if (_userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(context,
              en: 'No email found for this account',
              fr: 'Aucun e-mail trouvé pour ce compte',
              ar: 'لا يوجد بريد إلكتروني لهذا الحساب')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          BodyTalkApp.tr(context,
              en: 'Reset Password',
              fr: 'Réinitialiser le mot de passe',
              ar: 'إعادة تعيين كلمة المرور'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          BodyTalkApp.tr(context,
              en: 'A password reset link will be sent to:\n$_userEmail',
              fr: 'Un lien de réinitialisation sera envoyé à :\n$_userEmail',
              ar: 'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى:\n$_userEmail'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              BodyTalkApp.tr(context, en: 'Cancel', fr: 'Annuler', ar: 'إلغاء'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              BodyTalkApp.tr(context, en: 'Send', fr: 'Envoyer', ar: 'إرسال'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.requestPasswordReset(_userEmail);
      if (!mounted) return;
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                BodyTalkApp.tr(context,
                    en: 'Password reset link sent to your email ✅',
                    fr: 'Lien de réinitialisation envoyé à votre e-mail ✅',
                    ar: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك ✅')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show backend error message if available
        final errorMsg = result?['message'] ?? result?['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ??
                BodyTalkApp.tr(context,
                    en: 'Failed to send reset link. Please try again.',
                    fr: 'Échec de l\'envoi du lien. Veuillez réessayer.',
                    ar: 'فشل إرسال الرابط. حاول مرة أخرى.')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSyncPlan = prefs.getBool('auto_sync_plan') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _notifEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() => _loadingSubscription = true);
    try {
      final data = await ApiService.getSubscriptionStatus();
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _subscriptionStatus = data['status'] ?? 'free';
          _subscriptionType = data['subscription_type'];
          if (data['expiry_date'] != null) {
            _subscriptionExpiry = DateTime.tryParse(data['expiry_date']);
          }
          _loadingSubscription = false;
        });
      } else {
        setState(() => _loadingSubscription = false);
      }
    } catch (e) {
      debugPrint('❌ Failed to load subscription: $e');
      if (!mounted) return;
      setState(() => _loadingSubscription = false);
    }
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
        backgroundColor: _bg,
        title: Text(
          BodyTalkApp.tr(context,
              en: 'Delete account from this device',
              fr: 'Supprimer le compte de cet appareil',
              ar: 'حذف الحساب من هذا الجهاز'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          BodyTalkApp.tr(context,
              en: 'Only data stored on this device will be deleted.\nYou can log in again or create a new account later.\n\nDo you want to continue?',
              fr: 'Seules les données stockées sur cet appareil seront supprimées.\nVous pourrez vous reconnecter ou créer un nouveau compte plus tard.\n\nVoulez-vous continuer?',
              ar: 'سيتم حذف بيانات حسابك المخزّنة على هذا الجهاز فقط.\nيمكنك لاحقًا تسجيل الدخول أو إنشاء حساب جديد.\n\nهل تريد المتابعة؟'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              BodyTalkApp.tr(context, en: 'Cancel', fr: 'Annuler', ar: 'إلغاء'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              BodyTalkApp.tr(context,
                  en: 'Confirm', fr: 'Confirmer', ar: 'تأكيد'),
              style: const TextStyle(color: Colors.white),
            ),
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
          msg ??
              BodyTalkApp.tr(context,
                  en: 'This feature will be activated in upcoming updates ✨',
                  fr: 'Cette fonctionnalité sera activée dans les prochaines mises à jour ✨',
                  ar: 'سيتم تفعيل هذه الميزة في التحديثات القادمة ✨'),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'male'),
                  title: Text(
                    BodyTalkApp.tr(context, en: 'Male', fr: 'Homme', ar: 'ذكر'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.male, color: Colors.white70),
                ),
                ListTile(
                  onTap: () => Navigator.pop(ctx, 'female'),
                  title: Text(
                    BodyTalkApp.tr(context,
                        en: 'Female', fr: 'Femme', ar: 'أنثى'),
                    style: const TextStyle(color: Colors.white),
                  ),
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
      // Send to backend immediately
      final updated = await ApiService.updateProfile({'gender': result});
      if (!mounted) return;
      if (updated != null) {
        setState(() => _gender = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Gender updated ✅',
                fr: 'Genre mis à jour ✅',
                ar: 'تم تحديث الجنس ✅')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Failed to update gender',
                fr: 'Échec de la mise à jour du genre',
                ar: 'فشل تحديث الجنس')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                  style: const TextStyle(
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
      final prefs = await SharedPreferences.getInstance();
      final code = (result == 'العربية')
          ? 'ar'
          : (result == 'Français')
              ? 'fr'
              : 'en';
      await prefs.setString('app_language', code);
      // تطبيق اللغة فوراً بدون إعادة تشغيل
      if (!mounted) return;
      BodyTalkApp.setLocaleStatic(context, code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(context,
              en: 'Language changed ✅',
              fr: 'Langue changée ✅',
              ar: 'تم تغيير اللغة ✅')),
          backgroundColor: Colors.green,
        ),
      );
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
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'Select your approximate age',
                          fr: 'Sélectionnez votre âge approximatif',
                          ar: 'اختر عمرك التقريبي'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$tempAge ${BodyTalkApp.tr(context, en: 'years', fr: 'ans', ar: 'سنة')}',
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
                        child: Text(BodyTalkApp.tr(context,
                            en: 'Save', fr: 'Enregistrer', ar: 'حفظ')),
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
      // Send to backend immediately
      final updated = await ApiService.updateProfile({'age': result});
      if (!mounted) return;
      if (updated != null) {
        setState(() => _age = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Age updated ✅',
                fr: 'Âge mis à jour ✅',
                ar: 'تم تحديث العمر ✅')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Failed to update age',
                fr: 'Échec de la mise à jour de l\'âge',
                ar: 'فشل تحديث العمر')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
          title: Text(
            BodyTalkApp.tr(context,
                en: 'Profile & Settings',
                fr: 'Profil et paramètres',
                ar: 'الملف الشخصي والإعدادات'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      Expanded(
                        child: Text(
                          BodyTalkApp.tr(context,
                              en: 'Your BodyTalk AI account',
                              fr: 'Votre compte BodyTalk AI',
                              ar: 'حسابك في BodyTalk AI'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        BodyTalkApp.tr(context,
                            en: 'Beta', fr: 'Bêta', ar: 'إصدار تجريبي'),
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
                  title: BodyTalkApp.tr(context,
                      en: 'Personal information',
                      fr: 'Informations personnelles',
                      ar: 'المعلومات الشخصية'),
                  child: _loadingProfile
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                BodyTalkApp.tr(context,
                                    en: 'Name', fr: 'Nom', ar: 'الاسم'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                _userName.isNotEmpty
                                    ? _userName
                                    : BodyTalkApp.tr(context,
                                        en: 'Not set',
                                        fr: 'Non défini',
                                        ar: 'غير محدد'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70, size: 18),
                                onPressed: _editName,
                              ),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              height: 12,
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                BodyTalkApp.tr(context,
                                    en: 'Email',
                                    fr: 'E-mail',
                                    ar: 'البريد الإلكتروني'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                _userEmail.isNotEmpty
                                    ? _userEmail
                                    : BodyTalkApp.tr(context,
                                        en: 'Not set',
                                        fr: 'Non défini',
                                        ar: 'غير محدد'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70, size: 18),
                                onPressed: _editEmail,
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            BodyTalkApp.tr(context,
                                                en: 'Gender',
                                                fr: 'Genre',
                                                ar: 'الجنس'),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            () {
                                              if (_gender.isEmpty) {
                                                return BodyTalkApp.tr(context,
                                                    en: 'Not set',
                                                    fr: 'Non défini',
                                                    ar: 'غير محدد');
                                              }
                                              if (_gender == 'male') {
                                                return BodyTalkApp.tr(context,
                                                    en: 'Male',
                                                    fr: 'Homme',
                                                    ar: 'ذكر');
                                              }
                                              if (_gender == 'female') {
                                                return BodyTalkApp.tr(context,
                                                    en: 'Female',
                                                    fr: 'Femme',
                                                    ar: 'أنثى');
                                              }
                                              return _gender;
                                            }(),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            BodyTalkApp.tr(context,
                                                en: 'Age',
                                                fr: 'Âge',
                                                ar: 'العمر التقريبي'),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _age != null
                                                ? '$_age ${BodyTalkApp.tr(context, en: 'years', fr: 'ans', ar: 'سنة')}'
                                                : BodyTalkApp.tr(context,
                                                    en: 'Not set',
                                                    fr: 'Non défini',
                                                    ar: 'غير محدد'),
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
                              ],
                            ),
                          ],
                        ),
                ),

                // 🔐 إدارة الحساب
                _sectionCard(
                  icon: Icons.manage_accounts_outlined,
                  title: BodyTalkApp.tr(context,
                      en: 'Account management',
                      fr: 'Gestion du compte',
                      ar: 'إدارة الحساب'),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.lock_reset, color: Colors.white70),
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Change Password',
                              fr: 'Changer le mot de passe',
                              ar: 'تغيير كلمة المرور'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Reset via email',
                              fr: 'Réinitialiser par e-mail',
                              ar: 'إعادة تعيين عبر البريد'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: _showChangePasswordDialog,
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 12,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.alternate_email,
                            color: Colors.white70),
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Change Email',
                              fr: "Changer l'e-mail",
                              ar: 'تغيير البريد الإلكتروني'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Update account email',
                              fr: 'Mettre à jour l\'e-mail',
                              ar: 'تحديث البريد المرتبط بحسابك'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: _editEmail,
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
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Logout',
                              fr: 'Déconnexion',
                              ar: 'تسجيل الخروج'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Sign out',
                              fr: 'Se déconnecter',
                              ar: 'إغلاق الجلسة'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Delete account from this device',
                              fr: 'Supprimer le compte de cet appareil',
                              ar: 'حذف الحساب من هذا الجهاز'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Local data only',
                              fr: 'Données locales uniquement',
                              ar: 'البيانات المحلية فقط'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: _deleteAccountLocal,
                      ),
                    ],
                  ),
                ),

                // ⚙️ إعدادات التطبيق
                _sectionCard(
                  icon: Icons.settings_suggest_outlined,
                  title: BodyTalkApp.tr(context,
                      en: 'App settings',
                      fr: "Paramètres de l'application",
                      ar: 'إعدادات التطبيق'),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _orange,
                        inactiveThumbColor: Colors.grey.shade500,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.12),
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Enable Notifications',
                              fr: 'Activer les notifications',
                              ar: 'تفعيل الإشعارات'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Reminders for analysis',
                              fr: 'Rappels pour l\'analyse',
                              ar: 'تذكيرات للتحليل'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _notifEnabled,
                        onChanged: (v) async {
                          setState(() => _notifEnabled = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notifications_enabled', v);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? BodyTalkApp.tr(context,
                                      en: 'Notifications enabled 🔔',
                                      fr: 'Notifications activées 🔔',
                                      ar: 'تم تفعيل الإشعارات 🔔')
                                  : BodyTalkApp.tr(context,
                                      en: 'Notifications disabled',
                                      fr: 'Notifications désactivées',
                                      ar: 'تم إيقاف الإشعارات')),
                              backgroundColor: v ? Colors.green : Colors.grey,
                            ),
                          );
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
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Dark Mode',
                              fr: 'Mode sombre',
                              ar: 'الوضع الداكن'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Dark/Light theme',
                              fr: 'Thème sombre/clair',
                              ar: 'داكن/فاتح'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _darkMode,
                        onChanged: (v) {
                          setState(() => _darkMode = v);
                          BodyTalkApp.setThemeModeStatic(context, v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? BodyTalkApp.tr(context,
                                      en: 'Dark mode enabled 🌙',
                                      fr: 'Mode sombre activé 🌙',
                                      ar: 'تم تفعيل الوضع الداكن 🌙')
                                  : BodyTalkApp.tr(context,
                                      en: 'Light mode enabled ☀️',
                                      fr: 'Mode clair activé ☀️',
                                      ar: 'تم تفعيل الوضع الفاتح ☀️')),
                              backgroundColor: Colors.green,
                            ),
                          );
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
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Auto-sync plans',
                              fr: 'Synchroniser automatiquement les plans',
                              ar: 'مزامنة الخطط تلقائيًا'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Sync meal & workout plans',
                              fr: 'Synchroniser repas et entraînement',
                              ar: 'مزامنة خطط الوجبات والتمارين'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _autoSyncPlan,
                        onChanged: (v) async {
                          setState(() => _autoSyncPlan = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('auto_sync_plan', v);
                          _showSoonSnack(v
                              ? BodyTalkApp.tr(context,
                                  en: 'Auto-sync enabled ✅',
                                  fr: 'Synchronisation automatique activée ✅',
                                  ar: 'تم تفعيل المزامنة التلقائية بين الخطط ✅')
                              : BodyTalkApp.tr(context,
                                  en: 'Auto-sync disabled',
                                  fr: 'Synchronisation automatique désactivée',
                                  ar: 'تم إيقاف المزامنة التلقائية بين الخطط'));
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
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Enable biometric login',
                              fr: 'Activer la connexion biométrique',
                              ar: 'تفعيل تسجيل الدخول بالبصمة'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          BodyTalkApp.tr(context,
                              en: 'Face ID / Fingerprint',
                              fr: 'Face ID / Empreinte',
                              ar: 'Face ID / بصمة'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _biometricEnabled,
                        onChanged: (v) async {
                          if (v) {
                            // Check if biometric is available
                            final canUse = await FaceAuthService.instance
                                .canCheckBiometrics();
                            if (!canUse) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(BodyTalkApp.tr(context,
                                      en: 'Biometric authentication not available on this device.',
                                      fr: "L'authentification biométrique n'est pas disponible sur cet appareil.",
                                      ar: 'المصادقة البيومترية غير متوفرة على هذا الجهاز.')),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            // Test authentication
                            final authenticated =
                                await FaceAuthService.instance.authenticate(
                              reason: BodyTalkApp.tr(context,
                                  en: 'Verify to enable biometric login',
                                  fr: 'Vérifiez pour activer la connexion biométrique',
                                  ar: 'تحقق لتفعيل تسجيل الدخول بالبصمة'),
                            );
                            if (!authenticated) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(BodyTalkApp.tr(context,
                                      en: 'Biometric verification failed.',
                                      fr: 'Échec de la vérification biométrique.',
                                      ar: 'فشل التحقق البيومتري.')),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                          }
                          setState(() => _biometricEnabled = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('biometric_enabled', v);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? BodyTalkApp.tr(context,
                                      en: 'Biometric login enabled ✅',
                                      fr: 'Connexion biométrique activée ✅',
                                      ar: 'تم تفعيل تسجيل الدخول بالبصمة ✅')
                                  : BodyTalkApp.tr(context,
                                      en: 'Biometric login disabled',
                                      fr: 'Connexion biométrique désactivée',
                                      ar: 'تم إيقاف تسجيل الدخول بالبصمة')),
                              backgroundColor: v ? Colors.green : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                _sectionCard(
                  icon: Icons.language,
                  title: BodyTalkApp.tr(context,
                      en: 'Language', fr: 'Langue', ar: 'اللغة'),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          BodyTalkApp.tr(context,
                              en: 'Language', fr: 'Langue', ar: 'اللغة'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          () {
                            final code =
                                BodyTalkApp.getLocaleCode(context) ?? 'en';
                            if (code == 'ar') return 'العربية';
                            if (code == 'fr') return 'Français';
                            return 'English';
                          }(),
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
                  title: BodyTalkApp.tr(context,
                      en: 'Subscription Status',
                      fr: "Statut d'abonnement",
                      ar: 'حالة الاشتراك'),
                  child: _loadingSubscription
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BodyTalkApp.tr(context,
                                  en: 'Current status:',
                                  fr: 'Statut actuel :',
                                  ar: 'الوضع الحالي:'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _subscriptionStatus == 'active'
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : _subscriptionStatus == 'trial'
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _subscriptionStatus == 'active'
                                        ? Icons.check_circle
                                        : _subscriptionStatus == 'trial'
                                            ? Icons.timer
                                            : Icons.block,
                                    color: _subscriptionStatus == 'active'
                                        ? Colors.greenAccent
                                        : _subscriptionStatus == 'trial'
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _subscriptionStatus == 'active'
                                        ? BodyTalkApp.tr(context,
                                            en: 'Premium',
                                            fr: 'Premium',
                                            ar: 'بريميوم')
                                        : _subscriptionStatus == 'trial'
                                            ? BodyTalkApp.tr(context,
                                                en: 'Free Trial',
                                                fr: 'Essai gratuit',
                                                ar: 'تجربة مجانية')
                                            : BodyTalkApp.tr(context,
                                                en: 'Free',
                                                fr: 'Gratuit',
                                                ar: 'مجاني'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_subscriptionType != null)
                              const SizedBox(height: 8),
                            if (_subscriptionType != null)
                              Text(
                                '${BodyTalkApp.tr(context, en: 'Type:', fr: 'Type :', ar: 'النوع:')} $_subscriptionType',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            if (_subscriptionExpiry != null)
                              const SizedBox(height: 4),
                            if (_subscriptionExpiry != null)
                              Text(
                                '${BodyTalkApp.tr(context, en: 'Expires:', fr: 'Expire :', ar: 'تنتهي:')} ${_subscriptionExpiry!.year}-${_subscriptionExpiry!.month.toString().padLeft(2, '0')}-${_subscriptionExpiry!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              BodyTalkApp.tr(context,
                                  en: 'In future updates, you can activate a free trial (e.g. 3 days), then subscribe monthly or yearly via Apple Pay and Google Pay for deeper analysis and more personalized plans.',
                                  fr: 'Dans les futures mises à jour, vous pourrez activer un essai gratuit (par ex. 3 jours), puis vous abonner mensuellement ou annuellement via Apple Pay et Google Pay pour des analyses plus approfondies.',
                                  ar: 'في النسخ القادمة يمكن تفعيل تجربة مجانية (مثلاً 3 أيام)، ثم الاشتراك الشهري أو السنوي عبر Apple Pay و Google Pay للوصول إلى تحليلات أعمق وخطط مخصصة.'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await ApiService
                                      .activateTestSubscription();
                                  if (!mounted) return;
                                  if (result != null &&
                                      result['is_active'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(BodyTalkApp.tr(context,
                                            en: 'Test subscription activated! ✅',
                                            fr: 'Abonnement test activé! ✅',
                                            ar: 'تم تفعيل الاشتراك التجريبي! ✅')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadUserProfile();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(BodyTalkApp.tr(context,
                                            en: 'Failed to activate subscription',
                                            fr: "Échec de l'activation",
                                            ar: 'فشل تفعيل الاشتراك')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.star_rounded, size: 18),
                                label: Text(
                                  BodyTalkApp.tr(context,
                                      en: 'Activate Test Subscription',
                                      fr: 'Activer l\'abonnement test',
                                      ar: 'تفعيل الاشتراك التجريبي'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                  title: BodyTalkApp.tr(context,
                      en: 'About the app',
                      fr: "À propos de l'application",
                      ar: 'حول التطبيق'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BodyTalkApp.tr(context,
                            en: 'BodyTalk AI – Your smart health companion',
                            fr: 'BodyTalk AI – Votre compagnon santé intelligent',
                            ar: 'BodyTalk AI – مساعدك نحو حياة صحية أذكى'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        BodyTalkApp.tr(context,
                            en: 'BodyTalk AI helps you understand your health status by analyzing photos of your body and meals, providing insights and tips to improve your lifestyle, track progress, and make better health decisions step by step.',
                            fr: 'BodyTalk AI vous aide à comprendre votre état de santé en analysant les photos de votre corps et de vos repas, fournissant des conseils pour améliorer votre mode de vie et suivre vos progrès.',
                            ar: 'يهدف BodyTalk AI إلى مساعدتك على فهم وضعك الصحي بشكل أبسط، من خلال تحليل صور جسمك ووجباتك، وتقديم ملاحظات ونصائح تساعدك على تحسين نمط حياتك ومتابعة تقدمك.'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        BodyTalkApp.tr(context,
                            en: 'This app is not a substitute for a doctor\'s consultation, but a supportive tool to give you a clearer view of your body and eating habits.',
                            fr: 'Cette application ne remplace pas la consultation médicale, mais est un outil de soutien pour mieux comprendre votre corps et vos habitudes alimentaires.',
                            ar: 'التطبيق ليس بديلاً عن استشارة الطبيب أو الأخصائي، لكنه أداة داعمة تمنحك رؤية أوضح عن جسمك وعاداتك الغذائية.'),
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
                            onPressed: () => _showSoonSnack(BodyTalkApp.tr(
                                context,
                                en: 'Privacy Policy page will be added soon 📃',
                                fr: 'La page de politique de confidentialité sera ajoutée bientôt 📃',
                                ar: 'سيتم إضافة صفحة سياسة الخصوصية لاحقًا 📃')),
                            child: Text(
                              BodyTalkApp.tr(context,
                                  en: 'Privacy Policy',
                                  fr: 'Politique de confidentialité',
                                  ar: 'سياسة الخصوصية'),
                              style: const TextStyle(
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
                            onPressed: () => _showSoonSnack(BodyTalkApp.tr(
                                context,
                                en: 'Terms & Conditions will be added soon 📜',
                                fr: 'Les conditions générales seront ajoutées bientôt 📜',
                                ar: 'سيتم إضافة الشروط والأحكام قريبًا 📜')),
                            child: Text(
                              BodyTalkApp.tr(context,
                                  en: 'Terms & Conditions',
                                  fr: 'Conditions générales',
                                  ar: 'الشروط والأحكام'),
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'v1.0.0',
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
                    BodyTalkApp.tr(context,
                        en: 'Settings can be linked to a real account and server in the future.',
                        fr: 'Les paramètres peuvent être liés à un compte réel et un serveur à l\'avenir.',
                        ar: 'يمكن ربط هذه الإعدادات لاحقًا بحساب حقيقي وسيرفر.'),
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
