// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Server URL
  static String _baseUrl = 'http://10.0.2.2:8000';

  static String get baseUrl => _baseUrl;

  // Current token in memory
  static String? _token;

  // Secure storage for auth token
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const String _tokenKey = 'access_token';

  /// Initialize server URL once in main()
  static Future<void> initServer() async {
    // Use Render server for production
    _baseUrl = 'https://bodytalk-server.onrender.com';

    // Load stored token from secure storage
    try {
      _token = await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Failed to read token from secure storage: $e');
      _token = null;
    }
  }

  /// Save/clear token in secure storage + memory
  static Future<void> _saveToken(String? token) async {
    _token = token;
    try {
      if (token == null) {
        await _secureStorage.delete(key: _tokenKey);
      } else {
        await _secureStorage.write(key: _tokenKey, value: token);
      }
    } catch (e) {
      debugPrint('Failed to save token to secure storage: $e');
    }
  }

  /// التحقق هل المستخدم مسجّل الدخول
  static bool get isLoggedIn => _token != null;

  /// إخراج التوكن الحالي (لو احتجته)
  static String? get token => _token;

  /// الهيدرز الافتراضية
  static Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ==========================
  //       Auth & User
  // ==========================

  /// تسجيل مستخدم جديد
  static Future<http.Response?> registerUser(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      debugPrint('registerUser error: $e');
      return null;
    }
  }

  /// تسجيل الدخول – يرجع الـ Map اللي فيها access_token
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': password,
        },
        encoding: Encoding.getByName('utf-8'),
      );

      debugPrint("LOGIN STATUS: ${response.statusCode}");
      debugPrint("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          await _saveToken(accessToken);
        }
        return data;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Login Exception: $e");
      return null;
    }
  }

  /// Social Login (Google/Apple) - يرجع access_token
  static Future<Map<String, dynamic>?> socialLogin({
    required String provider,
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? photoUrl,
    String? userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/social-login');
    final payload = {
      'provider': provider,
      'id_token': idToken,
      'access_token': accessToken,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'user_id': userId,
    };
    debugPrint('🌐 Social Login Request: $uri');
    debugPrint('📦 Provider: $provider');
    debugPrint('📧 Email: $email');
    debugPrint('👤 Name: $name');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📥 Social Login Status: ${response.statusCode}');
      debugPrint('📥 Social Login Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null) {
          await _saveToken(token);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['detail'] ?? 'Social login failed'};
      }
    } catch (e) {
      debugPrint('❌ Social Login Exception: $e');
      return {'error': e.toString()};
    }
  }

  /// طلب إعادة تعيين كلمة المرور
  static Future<Map<String, dynamic>?> requestPasswordReset(
      String email) async {
    final uri = Uri.parse('$_baseUrl/auth/forgot-password');
    debugPrint('🔐 Password Reset Request: $uri');
    debugPrint('📧 Email: $email');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['detail'] ?? 'Password reset failed'};
      }
    } catch (e) {
      debugPrint('❌ requestPasswordReset error: $e');
      return {'error': e.toString()};
    }
  }

  /// تسجيل الخروج – يمسح التوكن
  static Future<void> logout() async {
    await _saveToken(null);
  }

  /// الحصول على بيانات المستخدم الحالية من /auth/me
  static Future<Map<String, dynamic>?> getAuthMe() async {
    final uri = Uri.parse('$_baseUrl/auth/me');

    try {
      final response = await http.get(
        uri,
        headers: _headers(auth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('getAuthMe failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('getAuthMe error: $e');
      return null;
    }
  }

  /// الحصول على بيانات البروفايل الكاملة من /users/me
  static Future<Map<String, dynamic>?> getProfile() async {
    final uri = Uri.parse('$_baseUrl/users/me');

    try {
      final response = await http.get(
        uri,
        headers: _headers(auth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'getProfile failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  /// تحديث بيانات البروفايل
  static Future<Map<String, dynamic>?> updateProfile(
      Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/users/me');

    try {
      final response = await http.put(
        uri,
        headers: _headers(auth: true),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'updateProfile failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return null;
    }
  }

  // ==========================
  //    Subscription (Server)
  // ==========================

  /// قراءة حالة الاشتراك من السيرفر
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    final uri = Uri.parse('$_baseUrl/subscriptions/me');
    try {
      final response = await http.get(
        uri,
        headers: _headers(auth: true),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'getSubscriptionStatus failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('getSubscriptionStatus error: $e');
      return null;
    }
  }

  /// تفعيل اشتراك اختباري عبر السيرفر
  static Future<Map<String, dynamic>?> activateTestSubscription() async {
    final uri = Uri.parse('$_baseUrl/subscriptions/activate-test');
    try {
      final response = await http.post(
        uri,
        headers: _headers(auth: true),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'activateTestSubscription failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('activateTestSubscription error: $e');
      return null;
    }
  }

  // ==========================
  //       Body / Food
  // ==========================

  /// تحليل صورة الجسم – /analysis/body
  static Future<Map<String, dynamic>?> analyzeBodyImage(File imageFile,
      {String? language}) async {
    final uri = Uri.parse('$_baseUrl/analysis/body');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(auth: true))
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    // إضافة اللغة كمعامل
    if (language != null) {
      request.fields['language'] = language;
    }

    debugPrint('🌐 Body Analysis Request: $uri');
    debugPrint('🌍 Language: ${language ?? "not specified"}');

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('📥 Body Analysis Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'analyzeBodyImage failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('analyzeBodyImage error: $e');
      return null;
    }
  }

  /// تحليل صورتين للجسم (أمامية + جانبية) – /analysis/body-two
  static Future<Map<String, dynamic>?> analyzeBodyTwoImages(
      File frontImage, File sideImage,
      {String? language}) async {
    final uri = Uri.parse('$_baseUrl/analysis/body-two');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(auth: true))
      ..files.add(
        await http.MultipartFile.fromPath('front_file', frontImage.path),
      )
      ..files.add(
        await http.MultipartFile.fromPath('side_file', sideImage.path),
      );

    if (language != null) {
      request.fields['language'] = language;
    }

    debugPrint('🌐 Body Two-Image Analysis Request: $uri');
    debugPrint('🌍 Language: ${language ?? "not specified"}');

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('📥 Body Two-Image Analysis Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'analyzeBodyTwoImages failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('analyzeBodyTwoImages error: $e');
      return null;
    }
  }

  /// تحليل صورة الأكل – /analysis/food
  static Future<Map<String, dynamic>?> analyzeFoodImage(File imageFile,
      {String? language, String? cuisine}) async {
    final uri = Uri.parse('$_baseUrl/analysis/food');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(auth: true))
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    // إضافة اللغة والمطبخ كمعاملات
    if (language != null) {
      request.fields['language'] = language;
    }
    if (cuisine != null) {
      request.fields['cuisine'] = cuisine;
    }

    debugPrint('🌐 Food Analysis Request: $uri');
    debugPrint('🌍 Language: ${language ?? "not specified"}');
    debugPrint('🍲 Cuisine: ${cuisine ?? "not specified"}');

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('📥 Food Analysis Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 422) {
        // NOT_FOOD_IMAGE or validation error from backend
        debugPrint('analyzeFoodImage rejected: ${response.body}');
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'error_code': errorData['error_code'] ?? 'NOT_FOOD_IMAGE',
            'message': errorData['message'] ??
                errorData['detail'] ??
                'Image validation failed',
          };
        } catch (_) {
          return {
            'success': false,
            'error_code': 'NOT_FOOD_IMAGE',
            'message': 'This image was rejected by the server.',
          };
        }
      } else {
        debugPrint(
            'analyzeFoodImage failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('analyzeFoodImage error: $e');
      return null;
    }
  }

  // ==========================
  //       Subscription
  // ==========================

  /// حالة الاشتراك من /subscriptions/me
  static Future<bool> isPremium() async {
    final uri = Uri.parse('$_baseUrl/subscriptions/me');

    try {
      final response = await http.get(
        uri,
        headers: _headers(auth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['is_active'] == true;
      } else {
        debugPrint('isPremium failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('isPremium error: $e');
      return false;
    }
  }

  // ==========================
  //        History
  // ==========================

  /// تاريخ تحليل الجسم – /analysis/body/history
  static Future<List<dynamic>?> getBodyHistory() async {
    final uri = Uri.parse('$_baseUrl/analysis/body/history');
    try {
      final response = await http.get(uri, headers: _headers(auth: true));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return null;
      } else {
        debugPrint(
            'getBodyHistory failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('getBodyHistory error: $e');
      return null;
    }
  }

  /// تاريخ تحليل الوجبات – /analysis/food/history
  static Future<List<dynamic>?> getFoodHistory() async {
    final uri = Uri.parse('$_baseUrl/analysis/food/history');
    try {
      final response = await http.get(uri, headers: _headers(auth: true));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return null;
      } else {
        debugPrint(
            'getFoodHistory failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('getFoodHistory error: $e');
      return null;
    }
  }

  // ==========================
  //           Plans
  // ==========================

  /// حفظ خطة التمارين على السيرفر
  static Future<Map<String, dynamic>?> saveWorkoutPlan({
    required int durationWeeks,
    required String focus,
  }) async {
    final uri = Uri.parse('$_baseUrl/plans/workout');
    try {
      final response = await http.post(
        uri,
        headers: _headers(auth: true),
        body: jsonEncode({
          'duration_weeks': durationWeeks,
          'focus': focus,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'saveWorkoutPlan failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('saveWorkoutPlan error: $e');
      return null;
    }
  }

  /// استرجاع خطة التمارين الحالية
  static Future<Map<String, dynamic>?> getWorkoutPlan() async {
    final uri = Uri.parse('$_baseUrl/plans/workout/current');
    try {
      final response = await http.get(uri, headers: _headers(auth: true));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('getWorkoutPlan error: $e');
      return null;
    }
  }

  /// حفظ خطة الوجبات على السيرفر
  static Future<Map<String, dynamic>?> saveMealPlan({
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    final uri = Uri.parse('$_baseUrl/plans/meal');
    try {
      final response = await http.post(
        uri,
        headers: _headers(auth: true),
        body: jsonEncode({
          'calories_target': calories,
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            'saveMealPlan failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('saveMealPlan error: $e');
      return null;
    }
  }

  /// استرجاع خطة الوجبات الحالية
  static Future<Map<String, dynamic>?> getMealPlan() async {
    final uri = Uri.parse('$_baseUrl/plans/meal/current');
    try {
      final response = await http.get(uri, headers: _headers(auth: true));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('getMealPlan error: $e');
      return null;
    }
  }
}
