import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _baseUrl = "http://10.0.2.2:8000/api"; // Ganti dengan IP lokalmu
  static final storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // WAJIB
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      print("Response login: $data"); // <-- Debug log

      if (response.statusCode == 200 && data['success'] == true) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'role', value: data['role']);

        return {
          'status': 'success',
          'message': 'Login berhasil',
          'role': data['role'], // ✅ Tambahkan ini agar bisa dipakai di LoginView
        };
        } else {
        return {
          'status': 'error',
          'message': data['message'] ?? 'Login gagal'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan jaringan atau server'
      };
    }
  }


  static Future<void> logout() async {
    await storage.deleteAll();
  }

  static Future<String?> getToken() => storage.read(key: 'token');
  static Future<String?> getRole() => storage.read(key: 'role');
}