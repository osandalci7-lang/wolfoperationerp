import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: AppConstants.tokenKey);
    final userStr = await _storage.read(key: AppConstants.userKey);
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        _token = data['data']['access_token'];
        _user = data['data']['user'];
        await _storage.write(key: AppConstants.tokenKey, value: _token);
        await _storage.write(
            key: AppConstants.userKey, value: jsonEncode(_user));
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
