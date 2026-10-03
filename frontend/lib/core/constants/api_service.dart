import 'dart:convert';

import 'package:frontend/core/constants/api_constant.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print("api response ");
      return data;
    } else {
      throw data["message"] ?? "An error occurred";
    }
  }
}
