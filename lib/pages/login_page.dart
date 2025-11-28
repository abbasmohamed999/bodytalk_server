// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bodytalk_app/main.dart';

import '../services/face_auth_service.dart';
import '../services/api_service.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _remember = false;

  static const Color _bg = Color(0xFF020617);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _black = Color(0xFF0B0F19);
  static const Color _orange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _email.text = prefs.getString('email') ?? '';
      _password.text = prefs.getString('password') ?? '';
      _remember = _email.text.isNotEmpty && _password.text.isNotEmpty;
    });
  }

  /// ✅ تسجيل الدخول الحقيقي عبر السيرفر
  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _email.text.trim();
      final password = _password.text;

      final result = await ApiService.login(email: email, password: password);

      if (!mounted) return;

      // رجع شيء فيه خطأ
      if (result == null ||
          (result['access_token'] == null && result['error'] != null)) {
        final msg = result?['error']?.toString() ??
            BodyTalkApp.tr(
              context,
              en: 'Login failed. Check your credentials or internet connection.',
              fr: 'Échec de la connexion. Vérifiez vos identifiants ou votre connexion Internet.',
              ar: 'تعذر تسجيل الدخول. تحقق من البيانات أو من اتصال الإنترنت.',
            );
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // نجاح
      final prefs = await SharedPreferences.getInstance();
      if (_remember) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
      }

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(
            context,
            en: 'Login successful ✅',
            fr: 'Connexion réussie ✅',
            ar: 'تم تسجيل الدخول بنجاح ✅',
          )),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, HomePage.routeName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(
            context,
            en: 'Unexpected error occurred. Please try again.',
            fr: 'Une erreur inattendue s\'est produite. Veuillez réessayer.',
            ar: 'حدث خطأ غير متوقع أثناء تسجيل الدخول. حاول مرة أخرى.',
          )),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loginWithFace() async {
    setState(() => _loading = true);

    final ok = await FaceAuthService.instance.authenticate();

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      // تحقق من وجود توكن صالح قبل الدخول
      if (ApiService.token != null) {
        final me = await ApiService.getAuthMe();
        if (me != null) {
          Navigator.pushReplacementNamed(context, HomePage.routeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(BodyTalkApp.tr(
                context,
                en: 'Session expired. Please login with email and password.',
                fr: 'Session expirée. Veuillez vous connecter avec e-mail et mot de passe.',
                ar: 'انتهت صلاحية الجلسة. الرجاء تسجيل الدخول بالبريد وكلمة المرور.',
              )),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BodyTalkApp.tr(
              context,
              en: 'Please login once with email and password to enable biometric login.',
              fr: 'Veuillez vous connecter une fois avec e-mail et mot de passe pour activer la connexion biométrique.',
              ar: 'الرجاء تسجيل الدخول مرة واحدة بالبريد وكلمة المرور لتفعيل الدخول بالبصمة.',
            )),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BodyTalkApp.tr(
            context,
            en: 'Face ID / Biometric authentication failed',
            fr: 'Échec de l\'authentification Face ID / biométrique',
            ar: 'فشل التحقق عبر Face ID / البصمة',
          )),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Dialog for password reset
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B0F19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          BodyTalkApp.tr(context,
              en: 'Reset Password',
              fr: 'Réinitialiser le mot de passe',
              ar: 'إعادة تعيين كلمة المرور'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              BodyTalkApp.tr(context,
                  en: 'Enter your email address and we will send you a password reset link.',
                  fr: 'Entrez votre adresse e-mail et nous vous enverrons un lien de réinitialisation.',
                  ar: 'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: BodyTalkApp.tr(context,
                    en: 'Email', fr: 'E-mail', ar: 'البريد الإلكتروني'),
                labelStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _orange, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              BodyTalkApp.tr(context, en: 'Cancel', fr: 'Annuler', ar: 'إلغاء'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(BodyTalkApp.tr(context,
                        en: 'Please enter a valid email address',
                        fr: 'Veuillez entrer une adresse e-mail valide',
                        ar: 'الرجاء إدخال عنوان بريد إلكتروني صالح')),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              // Call password reset API
              final result = await ApiService.requestPasswordReset(email);

              Navigator.pop(ctx);

              if (!mounted) return;

              if (result != null && result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(BodyTalkApp.tr(context,
                        en: 'Password reset link sent to your email ✅',
                        fr: 'Lien de réinitialisation envoyé à votre e-mail ✅',
                        ar: 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني ✅')),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(BodyTalkApp.tr(context,
                        en: 'Failed to send reset link. Please try again.',
                        fr: 'Échec de l\'envoi du lien. Veuillez réessayer.',
                        ar: 'فشل إرسال رابط إعادة التعيين. حاول مرة أخرى.')),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            child: Text(BodyTalkApp.tr(context,
                en: 'Send', fr: 'Envoyer', ar: 'إرسال')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
                // الهيدر العلوي
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
                          Icons.lock_outline,
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
                          en: 'Sign in',
                          fr: 'Se connecter',
                          ar: 'تسجيل الدخول',
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

                // أيقونة المستخدم
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
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 54),
                  ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Welcome back 👋',
                      fr: 'Bienvenue 👋',
                      ar: 'مرحبًا بعودتك 👋',
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
                      en: 'Sign in to continue analyzing your body and meals.',
                      fr: 'Connectez-vous pour continuer l’analyse de votre corps et de vos repas.',
                      ar: 'سجل دخولك للمتابعة في تحليل جسمك ووجباتك.',
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
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return BodyTalkApp.tr(context,
                                  en: 'Password is too short',
                                  fr: 'Le mot de passe est trop court',
                                  ar: 'كلمة المرور قصيرة جدًا');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              onChanged: (v) =>
                                  setState(() => _remember = v ?? false),
                              activeColor: _orange,
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              BodyTalkApp.tr(context,
                                  en: 'Remember me',
                                  fr: 'Se souvenir de moi',
                                  ar: 'تذكرني'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                BodyTalkApp.tr(context,
                                    en: 'Forgot password?',
                                    fr: 'Mot de passe oublié ?',
                                    ar: 'نسيت كلمة المرور؟'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
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
                                      en: 'Logging in...',
                                      fr: 'Connexion en cours...',
                                      ar: 'جارٍ تسجيل الدخول...')
                                  : BodyTalkApp.tr(context,
                                      en: 'Login',
                                      fr: 'Se connecter',
                                      ar: 'تسجيل الدخول'),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.face_retouching_natural),
                            label: Text(
                              BodyTalkApp.tr(context,
                                  en: 'Login with Face ID / Biometric',
                                  fr: 'Connexion avec Face ID / biométrie',
                                  ar: 'تسجيل الدخول عبر Face ID / البصمة'),
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _loading ? null : _loginWithFace,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // إنشاء حساب
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: Text(
                    BodyTalkApp.tr(context,
                        en: 'Don\'t have an account? Sign up',
                        fr: 'Pas de compte ? Inscrivez-vous',
                        ar: 'ليس لديك حساب؟ أنشئ حساب جديد'),
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
                    const Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'Your data is completely secure 🔒',
                          fr: 'Vos données sont entièrement sécurisées 🔒',
                          ar: 'بياناتك آمنة تمامًا 🔒'),
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
