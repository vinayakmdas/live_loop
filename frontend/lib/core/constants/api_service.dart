import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend/core/constants/api_constant.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw data["message"] ?? "An error occurred (Status ${response.statusCode})";
      }
    } on SocketException {
      throw "Unable to connect to the server. Please check your connection or server.";
    } on TimeoutException {
      throw "Connection timed out. Please check if the backend server is running.";
    } on FormatException {
      throw "Invalid response format from server.";
    } catch (e) {
      if (e is String) rethrow;
      throw e.toString();
    }
  }
}

