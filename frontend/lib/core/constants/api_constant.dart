import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5001";
    }

    if (Platform.isAndroid) {
      return "http://192.168.1.23:5001";
    }

    return "http://localhost:5001";
  }

  static const String loginEndpoint = "/api/auth/login";
  static const String registerEndpoint = "/api/auth/register";
}