import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://norden.wolfoperation.com';
  static const String apiUrl = '$baseUrl/api/v1';
  static const String appName = 'WolfOperation';
  static const String appVersion = '1.0.0';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String subdomainKey = 'subdomain';
}

class AppColors {
  // Web'den birebir
  static const Color primary = Color(0xFF1a73e8);
  static const Color bgDark = Color(0xFF0d1117);
  static const Color bgCard = Color(0xFF161b22);
  static const Color bgCardHover = Color(0xFF1c2128);
  static const Color textPrimary = Color(0xFFe6edf3);
  static const Color textSecondary = Color(0xFF8b949e);
  static const Color border = Color(0xFF30363d);
  static const Color success = Color(0xFF238636);
  static const Color warning = Color(0xFFd29922);
  static const Color danger = Color(0xFFda3633);
  static const Color navyDark = Color(0xFF1a3a6b);

  // Web ERP renkleri
  static const Color msBlue = Color(0xFF0078d4);
  static const Color msTeal = Color(0xFF038387);
  static const Color msOrange = Color(0xFFff8c00);
  static const Color msRed = Color(0xFFd13438);
  static const Color msPurple = Color(0xFF8764b8);
  static const Color msGreen = Color(0xFF107c10);
  static const Color msDarkRed = Color(0xFF8b0000);
}

double toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
