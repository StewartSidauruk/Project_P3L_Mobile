// services/merchandise_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MerchandiseService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static final storage = FlutterSecureStorage();

  static Future<List<dynamic>> fetchMerchandise() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/merchandise'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat merchandise');
    }
  }

  // Modifikasi fungsi tukarPoin untuk menerima jumlah_klaim
  static Future<Map<String, dynamic>> tukarPoin(int idPembeli, int idMerchandise, int jumlahKlaim) async {
    final token = await storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/tukar-poin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'id_pembeli': idPembeli,
        'id_merchandise': idMerchandise,
        'jumlah_klaim': jumlahKlaim,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // ✅ aman
    } else {
      final data = json.decode(response.body);
      throw data['message'] ?? 'Terjadi kesalahan saat menukar poin';
    }
  }

}