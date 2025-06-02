import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotifikasiService {
  static Future<List<String>> fetchNotifikasi() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse('https://yourdomain.com/api/penitip/notifikasi'),
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
}
