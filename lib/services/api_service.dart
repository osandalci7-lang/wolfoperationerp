import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(String endpoint, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 500, 'message': e.toString(), 'data': null};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 500, 'message': e.toString(), 'data': null};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 500, 'message': e.toString(), 'data': null};
    }
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 500, 'message': e.toString(), 'data': null};
    }
  }
}
