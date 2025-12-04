// lib/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bodytalk_app/services/api_service.dart';
import 'login_page.dart';
import 'package:bodytalk_app/main.dart';

class SignUpPage extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController(text: '25');
  final _height = TextEditingController(text: '170');
  final _weight = TextEditingController(text: '70');
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  bool _loading = false;

  static const Color _bg = Color(0xFF020617);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _black = Color(0xFF0B0F19);
  static const Color _orange = Color(0xFFFF9800);

  /// تسجيل حساب حقيقي عبر السيرفر
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await ApiService.registerUser({
        'email': _email.text.trim(),
        'password': _password.text,
        'full_name': _name.text.trim(),
        'gender': _gender,
        'age': int.tryParse(_age.text) ?? 25,
        'height_cm': double.tryParse(_height.text) ?? 170.0,
        'weight_kg': double.tryParse(_weight.text) ?? 70.0,
        'activity_level': _activityLevel,
        'goal': _goal,
      });

      if (!mounted) return;
      setState(() => _loading = false);

      if (response != null && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Account created successfully 🎉',
                fr: 'Compte créé avec succès 🎉',
                ar: 'تم إنشاء الحساب بنجاح 🎉')),
            backgroundColor: Colors.green,
          ),
        );

        // بعد الإنشاء نرجع لصفحة تسجيل الدخول
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(context,
                en: 'Failed to create account. Email may already be in use.',
                fr: 'Échec de la création du compte. L\'e-mail est peut-être déjà utilisé.',
                ar: 'فشل إنشاء الحساب. قد يكون البريد الإلكتروني مستخدمًا بالفعل.')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(context,
              en: 'An error occurred. Please try again.',
              fr: 'Une erreur s\'est produite. Veuillez réessayer.',
              ar: 'حدث خطأ. حاول مرة أخرى.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الهيدر
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'BodyTalk AI',
                            fr: 'BodyTalk AI',
                            ar: 'BodyTalk AI',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'New account',
                            fr: 'Nouveau compte',
                            ar: 'حساب جديد',
                          ),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // أيقونة
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_black, _blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 22,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 54),
                  ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Let’s create your account 😄',
                      fr: 'Créons votre compte 😄',
                      ar: 'لنبدأ إنشاء حسابك 😄',
                    ),
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      BodyTalkApp.tr(
                        context,
                        en: 'Enter your info to start analyzing your body and meals.',
                        fr: 'Entrez vos infos pour analyser votre corps.',
                        ar: 'سجّل معلوماتك للبدء في تحليل جسمك ووجباتك.',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // كارت النموذج
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617).withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: BodyTalkApp.tr(context,
                                en: 'Full name',
                                fr: 'Nom complet',
                                ar: 'الاسم الكامل'),
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 1.4),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return BodyTalkApp.tr(context,
                                  en: 'Enter your name',
                                  fr: 'Entrez votre nom',
                                  ar: 'أدخل اسمك');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: BodyTalkApp.tr(context,
                                en: 'Email',
                                fr: 'E-mail',
                                ar: 'البريد الإلكتروني'),
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 1.4),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return BodyTalkApp.tr(context,
                                  en: 'Enter email',
                                  fr: 'Entrez l’e-mail',
                                  ar: 'أدخل البريد الإلكتروني');
                            }
                            if (!v.contains('@')) {
                              return BodyTalkApp.tr(context,
                                  en: 'Invalid email format',
                                  fr: 'Format d’e-mail invalide',
                                  ar: 'صيغة البريد غير صحيحة');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: BodyTalkApp.tr(context,
                                en: 'Password',
                                fr: 'Mot de passe',
                                ar: 'كلمة المرور'),
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 1.4),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return BodyTalkApp.tr(context,
                                  en: 'Password must be at least 6 characters',
                                  fr: 'Le mot de passe doit contenir au moins 6 caractères',
                                  ar: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _gender,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                dropdownColor: const Color(0xFF0B0F19),
                                decoration: InputDecoration(
                                  labelText: BodyTalkApp.tr(context,
                                      en: 'Gender', fr: 'Genre', ar: 'الجنس'),
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.wc_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _orange, width: 1.4),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text(BodyTalkApp.tr(context,
                                        en: 'Male', fr: 'Homme', ar: 'ذكر')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text(BodyTalkApp.tr(context,
                                        en: 'Female', fr: 'Femme', ar: 'أنثى')),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _age,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: BodyTalkApp.tr(context,
                                      en: 'Age', fr: 'Âge', ar: 'العمر'),
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _orange, width: 1.4),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter age',
                                        fr: 'Entrez l\'âge',
                                        ar: 'أدخل العمر');
                                  }
                                  final age = int.tryParse(v);
                                  if (age == null || age < 13 || age > 100) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter valid age (13-100)',
                                        fr: 'Entrez un âge valide (13-100)',
                                        ar: 'أدخل عمرًا صحيحًا (13-100)');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _height,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: BodyTalkApp.tr(context,
                                      en: 'Height (cm)',
                                      fr: 'Taille (cm)',
                                      ar: 'الطول (سم)'),
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.straighten_outlined,
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _orange, width: 1.4),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter height',
                                        fr: 'Entrez la taille',
                                        ar: 'أدخل الطول');
                                  }
                                  final height = double.tryParse(v);
                                  if (height == null ||
                                      height < 100 ||
                                      height > 250) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter valid height (100-250 cm)',
                                        fr: 'Entrez une taille valide (100-250 cm)',
                                        ar: 'أدخل طولًا صحيحًا (100-250 سم)');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _weight,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: BodyTalkApp.tr(context,
                                      en: 'Weight (kg)',
                                      fr: 'Poids (kg)',
                                      ar: 'الوزن (كجم)'),
                                  labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.monitor_weight_outlined,
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.04),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _orange, width: 1.4),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter weight',
                                        fr: 'Entrez le poids',
                                        ar: 'أدخل الوزن');
                                  }
                                  final weight = double.tryParse(v);
                                  if (weight == null ||
                                      weight < 30 ||
                                      weight > 300) {
                                    return BodyTalkApp.tr(context,
                                        en: 'Enter valid weight (30-300 kg)',
                                        fr: 'Entrez un poids valide (30-300 kg)',
                                        ar: 'أدخل وزنًا صحيحًا (30-300 كجم)');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _activityLevel,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF0B0F19),
                          decoration: InputDecoration(
                            labelText: BodyTalkApp.tr(context,
                                en: 'Activity Level',
                                fr: 'Niveau d\'activité',
                                ar: 'مستوى النشاط'),
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.directions_run_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 1.4),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'sedentary',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Sedentary',
                                  fr: 'Sédentaire',
                                  ar: 'قليلاً')),
                            ),
                            DropdownMenuItem(
                              value: 'light',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Light Activity',
                                  fr: 'Activité légère',
                                  ar: 'نشاط خفيف')),
                            ),
                            DropdownMenuItem(
                              value: 'moderate',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Moderate Activity',
                                  fr: 'Activité modérée',
                                  ar: 'نشاط معتدل')),
                            ),
                            DropdownMenuItem(
                              value: 'active',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Active', fr: 'Actif', ar: 'نشط')),
                            ),
                            DropdownMenuItem(
                              value: 'very_active',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Very Active',
                                  fr: 'Très actif',
                                  ar: 'نشط جداً')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _activityLevel = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _goal,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF0B0F19),
                          decoration: InputDecoration(
                            labelText: BodyTalkApp.tr(context,
                                en: 'Goal', fr: 'Objectif', ar: 'الهدف'),
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.flag_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 1.4),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'lose',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Lose Weight',
                                  fr: 'Perdre du poids',
                                  ar: 'فقدان الوزن')),
                            ),
                            DropdownMenuItem(
                              value: 'maintain',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Maintain Weight',
                                  fr: 'Maintenir le poids',
                                  ar: 'الحفاظ على الوزن')),
                            ),
                            DropdownMenuItem(
                              value: 'gain',
                              child: Text(BodyTalkApp.tr(context,
                                  en: 'Gain Muscle',
                                  fr: 'Prendre du muscle',
                                  ar: 'زيادة العضلات')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _goal = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _loading
                                  ? BodyTalkApp.tr(context,
                                      en: 'Creating account...',
                                      fr: 'Création du compte...',
                                      ar: 'جارٍ إنشاء الحساب...')
                                  : BodyTalkApp.tr(context,
                                      en: 'Create account',
                                      fr: 'Créer un compte',
                                      ar: 'إنشاء الحساب'),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, LoginPage.routeName);
                  },
                  child: Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Already have an account? Sign in',
                      fr: 'Vous avez déjà un compte ? Connectez-vous',
                      ar: 'لديك حساب بالفعل؟ تسجيل الدخول',
                    ),
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      BodyTalkApp.tr(
                        context,
                        en: 'Your data is securely stored 🔐',
                        fr: 'Vos données sont stockées en toute sécurité 🔐',
                        ar: 'بياناتك محفوظة بشكل آمن 🔐',
                      ),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
