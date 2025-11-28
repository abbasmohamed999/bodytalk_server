// lib/services/bodytalk_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// خدمة الاتصال بسيرفر BodyTalk AI على Render.
///
/// ملاحظة:
/// لا تغير baseUrl إلا إذا تغيّر رابط السيرفر.
class BodyTalkApiService {
  /// رابط السيرفر على Render
  final String baseUrl = 'https://bodytalk-server.onrender.com';

  const BodyTalkApiService();

  /// فحص حالة السيرفر (GET /health)
  Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/health');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// تحليل الجسم (POST /analyze/body)
  Future<Map<String, dynamic>> analyzeBody(File imageFile) async {
    final url = Uri.parse('$baseUrl/analyze/body');

    final request = http.MultipartRequest('POST', url)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'فشل تحليل الجسم. كود الاستجابة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ أثناء تحليل الجسم: $e');
    }
  }

  /// تحليل الطعام (POST /analyze/food)
  Future<Map<String, dynamic>> analyzeFood(File imageFile) async {
    final url = Uri.parse('$baseUrl/analyze/food');

    final request = http.MultipartRequest('POST', url)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'فشل تحليل الطعام. كود الاستجابة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ أثناء تحليل الطعام: $e');
    }
  }
}
