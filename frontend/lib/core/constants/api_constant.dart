import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5001";
    }

    if (Platform.isAndroid) {
      return "http://192.168.1.19:5001";
    }

    return "http://localhost:5001";
  }

  static const String loginEndpoint = "/api/auth/login";
  static const String registerEndpoint = "/api/auth/register";
  static const String refreshEndpoint = "/api/auth/refresh";
  static const String logoutEndpoint = "/api/auth/logout";
  static const String meetingsEndpoint = "/api/meetings";
  static const String searchMeetingsEndpoint = "/api/meetings/search";
  static String searchMeetingsUrl(String query, {String type = 'private'}) =>
      "/api/meetings/search?q=${Uri.encodeComponent(query)}&type=$type";
  static const String joinMeetingEndpoint = "/api/meetings/join";
  static String meetingJoinEndpoint(String id) => "/api/meetings/$id/join";
}
