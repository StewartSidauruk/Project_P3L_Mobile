import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/kurir.dart';

class KurirService {
  static const String apiUrl = 'http://10.0.2.2:8000/api/kurir/me';

  static Future<Kurir> fetchProfil() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Kurir.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat profil kurir');
    }
  }
}
