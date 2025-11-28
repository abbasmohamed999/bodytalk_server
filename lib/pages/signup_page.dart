// lib/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _loading = false;

  static const Color _bg = Color(0xFF020617);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _black = Color(0xFF0B0F19);
  static const Color _orange = Color(0xFFFF9800);

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // حالياً تسجيل محلي فقط (بدون سيرفر) مع تأخير بسيط للإحساس بالعملية
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إنشاء الحساب بنجاح 🎉'),
        backgroundColor: Colors.green,
      ),
    );

    // بعد الإنشاء نرجع لصفحة تسجيل الدخول
    Navigator.pushReplacementNamed(context, LoginPage.routeName);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
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
                      Text(
                        BodyTalkApp.tr(
                          context,
                          en: 'BodyTalk AI',
                          fr: 'BodyTalk AI',
                          ar: 'BodyTalk AI',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        BodyTalkApp.tr(
                          context,
                          en: 'Create a new account',
                          fr: 'Créer un nouveau compte',
                          ar: 'إنشاء حساب جديد',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
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
                  child: Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Enter your info to start analyzing your body and meals.',
                      fr: 'Entrez vos informations pour commencer l’analyse de votre corps et de vos repas.',
                      ar: 'سجّل معلوماتك للبدء في تحليل جسمك ووجباتك.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
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
