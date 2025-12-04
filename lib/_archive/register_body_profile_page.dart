// lib/pages/register_body_profile_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bodytalk_app/services/api_service.dart';
import 'home_page.dart';
import 'package:bodytalk_app/main.dart';

class RegisterBodyProfilePage extends StatefulWidget {
  static const routeName = '/register-body-profile';

  const RegisterBodyProfilePage({super.key});

  @override
  State<RegisterBodyProfilePage> createState() =>
      _RegisterBodyProfilePageState();
}

class _RegisterBodyProfilePageState extends State<RegisterBodyProfilePage> {
  static const Color _bg = Color(0xFF020617);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFFF9800);

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _goal;

  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final data = {
      "email": email,
      "password": password,
      "full_name": _nameController.text.trim(),
      "gender": _gender,
      "age": int.tryParse(_ageController.text),
      "height_cm": double.tryParse(_heightController.text),
      "weight_kg": double.tryParse(_weightController.text),
      "activity_level": _activityLevel,
      "goal": _goal,
    };

    final response = await ApiService.registerUser(data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (response == null) {
      _showSnack(BodyTalkApp.tr(
        context,
        en: 'Unable to connect to server. Please check your connection.',
        fr: 'Impossible de se connecter au serveur. Vérifiez votre connexion.',
        ar: 'تعذر الاتصال بالسيرفر، تأكد أنه يعمل.',
      ));
      return;
    }

    if (response.statusCode == 200) {
      _showSnack(BodyTalkApp.tr(
        context,
        en: 'Account created successfully ✅',
        fr: 'Compte créé avec succès ✅',
        ar: 'تم إنشاء الحساب بنجاح ✅',
      ));

      final loginResult = await ApiService.login(
        email: email,
        password: password,
      );

      if (loginResult == null) {
        if (!mounted) return;
        _showSnack(BodyTalkApp.tr(
          context,
          en: 'Account created but auto-login failed.',
          fr: 'Compte créé mais la connexion automatique a échoué.',
          ar: 'تم إنشاء الحساب لكن فشل تسجيل الدخول تلقائيًا.',
        ));
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomePage.routeName);
    } else if (response.statusCode == 400 || response.statusCode == 409) {
      _showSnack(BodyTalkApp.tr(
        context,
        en: 'Email already in use or invalid data.',
        fr: 'E-mail déjà utilisé ou données invalides.',
        ar: 'البريد الإلكتروني مستخدم بالفعل أو بيانات غير صحيحة.',
      ));
    } else {
      _showSnack(BodyTalkApp.tr(
        context,
        en: 'Unexpected error: ${response.statusCode}',
        fr: 'Erreur inattendue: ${response.statusCode}',
        ar: 'حدث خطأ غير متوقع: ${response.statusCode}',
      ));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.black87,
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
          foregroundColor: Colors.white,
          title: Text(
            BodyTalkApp.tr(
              context,
              en: 'Create account and body info',
              fr: 'Créer un compte et les informations corporelles',
              ar: 'إنشاء حساب ومعلومات الجسم',
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 18),
                  _buildAccountSection(),
                  const SizedBox(height: 18),
                  _buildBodySection(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(BodyTalkApp.tr(context,
                              en: 'Create account and start',
                              fr: 'Créer le compte et commencer',
                              ar: 'إنشاء الحساب والبدء')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_blue, _orange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              BodyTalkApp.tr(
                context,
                en: 'We need some basic info to personalize analysis and tips 🎯',
                fr: "Nous avons besoin de quelques informations de base pour personnaliser l'analyse et les conseils 🎯",
                ar: 'نحتاج بعض المعلومات البسيطة\nلنخصص لك التحليل والنصائح 🎯',
              ),
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BodyTalkApp.tr(context,
                en: 'Account info',
                fr: 'Informations du compte',
                ar: 'بيانات الحساب'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _textField(
            controller: _nameController,
            label: BodyTalkApp.tr(context, en: 'Name', fr: 'Nom', ar: 'الاسم'),
            hint: BodyTalkApp.tr(context,
                en: 'e.g. Ahmed Mohamed',
                fr: 'ex. Ahmed Mohamed',
                ar: 'مثال: أحمد محمد'),
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 10),
          _textField(
            controller: _emailController,
            label: BodyTalkApp.tr(context,
                en: 'Email', fr: 'E-mail', ar: 'البريد الإلكتروني'),
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return BodyTalkApp.tr(context,
                    en: 'This field is required',
                    fr: 'Ce champ est requis',
                    ar: 'هذا الحقل مطلوب');
              }
              if (!v.contains('@')) {
                return BodyTalkApp.tr(context,
                    en: 'Invalid email',
                    fr: 'E-mail invalide',
                    ar: 'بريد غير صالح');
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          _textField(
            controller: _passwordController,
            label: BodyTalkApp.tr(context,
                en: 'Password', fr: 'Mot de passe', ar: 'كلمة المرور'),
            hint: BodyTalkApp.tr(context,
                en: 'At least 8 characters',
                fr: 'Au moins 8 caractères',
                ar: '٨ أحرف على الأقل'),
            obscureText: true,
            validator: (v) {
              if (v == null || v.length < 6) {
                return BodyTalkApp.tr(context,
                    en: 'Minimum 6 characters',
                    fr: 'Minimum 6 caractères',
                    ar: 'الحد الأدنى ٦ أحرف');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BodyTalkApp.tr(context,
                en: 'Body info and goal',
                fr: 'Informations corporelles et objectif',
                ar: 'معلومات الجسم والهدف'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown<String>(
                  value: _gender,
                  label: BodyTalkApp.tr(context,
                      en: 'Gender', fr: 'Genre', ar: 'الجنس'),
                  items: const [
                    'ذكر',
                    'أنثى',
                    'غير محدد',
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  controller: _ageController,
                  label: BodyTalkApp.tr(context,
                      en: 'Age', fr: 'Âge', ar: 'العمر'),
                  hint: BodyTalkApp.tr(context,
                      en: 'in years', fr: 'en années', ar: 'بالسنوات'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _heightController,
                  label: BodyTalkApp.tr(context,
                      en: 'Height (cm)', fr: 'Taille (cm)', ar: 'الطول (سم)'),
                  hint: BodyTalkApp.tr(context,
                      en: 'e.g. 175', fr: 'ex. 175', ar: 'مثال: 175'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  controller: _weightController,
                  label: BodyTalkApp.tr(context,
                      en: 'Weight (kg)', fr: 'Poids (kg)', ar: 'الوزن (كجم)'),
                  hint: BodyTalkApp.tr(context,
                      en: 'e.g. 72', fr: 'ex. 72', ar: 'مثال: 72'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _dropdown<String>(
            value: _activityLevel,
            label: BodyTalkApp.tr(context,
                en: 'Activity level',
                fr: "Niveau d'activité",
                ar: 'مستوى النشاط'),
            items: const [
              'منخفض',
              'متوسط',
              'مرتفع',
            ],
            onChanged: (v) => setState(() => _activityLevel = v),
          ),
          const SizedBox(height: 10),
          _dropdown<String>(
            value: _goal,
            label: BodyTalkApp.tr(context,
                en: 'Goal', fr: 'Objectif', ar: 'الهدف'),
            items: const [
              'فقدان وزن',
              'ثبات وزن',
              'زيادة عضل',
            ],
            onChanged: (v) => setState(() => _goal = v),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ??
          (v) {
            if (v == null || v.trim().isEmpty) {
              return BodyTalkApp.tr(context,
                  en: 'This field is required',
                  fr: 'Ce champ est requis',
                  ar: 'هذا الحقل مطلوب');
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
        hintText: hint != null
            ? BodyTalkApp.tr(context, en: hint, fr: hint, ar: hint)
            : null,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _orange, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String label,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: _bg,
      iconEnabledColor: Colors.white70,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _orange, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
