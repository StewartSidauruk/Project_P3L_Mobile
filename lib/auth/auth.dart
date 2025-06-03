import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  static const _baseUrl = "http://10.0.2.2:8000/api";
  static final storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      print("🔐 Response login: $data");

      if (response.statusCode == 200 && data['success'] == true) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'role', value: data['role']);

        // Kirim token FCM setelah login berhasil
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("📲 FCM token: $fcmToken");

        if (fcmToken != null) {
          final tokenResponse = await http.post(
            Uri.parse("$_baseUrl/simpan-token"),
            headers: {
              "Authorization": "Bearer ${data['token']}",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          );

          print("✅ Token simpan response: ${tokenResponse.body}");
        }

        return {
          'status': 'success',
          'message': 'Login berhasil',
          'role': data['role'],
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
    final token = await storage.read(key: 'token');

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse("$_baseUrl/logout-mobile"),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          print("✅ Token FCM berhasil dihapus dari server.");
        } else {
          print("⚠️ Gagal menghapus token FCM di server: ${response.body}");
        }
      } catch (e) {
        print("❌ Error saat logout: $e");
      }
    }

    // Baru hapus semua dari local
    await storage.deleteAll();
  }

  static Future<String?> getToken() => storage.read(key: 'token');
  static Future<String?> getRole() => storage.read(key: 'role');
}
