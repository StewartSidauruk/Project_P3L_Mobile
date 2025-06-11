import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PenitipService {
  // ✅ SOLUSI: Samakan format baseUrl seperti di HomeService (tanpa / di akhir)
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; 
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<List<dynamic>> fetchRiwayatPenitipan() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token tidak ditemukan, silahkan login ulang.');
    }

    // ✅ SOLUSI: URL kini menjadi '$baseUrl/penitip/transaksi'
    final response = await http.get(
      Uri.parse('$_baseUrl/penitip/transaksi'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Anda bisa menambahkan print di sini untuk debugging jika perlu
      // print('RESPONSE RIWAYAT: ${response.body}'); 
      return json.decode(response.body);
    } else {
      // Error ini akan tetap muncul jika ada masalah di backend
      print('Gagal, Status Code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Gagal memuat riwayat penitipan.');
    }
  }
}