import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotifikasiService {
  static Future<List<String>> fetchNotifikasi() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/penitip/notifikasi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Gagal memuat notifikasi');
    }
  }
  static Future<void> simpanTokenFCM(String token) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'token');

    await http.post(
      Uri.parse('http://10.0.2.2:8000/api/simpan-token'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'expo_push_token': token}),
    );
  }
}
