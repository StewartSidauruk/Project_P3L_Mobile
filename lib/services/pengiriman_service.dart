import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/transaksi_pengiriman.dart';

class PengirimanService {
  static const String apiUrl = 'http://10.0.2.2:8000/api/kurir/pengiriman'; // ubah IP jika pakai device fisik

  static Future<List<TransaksiPengiriman>> fetchPengiriman() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: "token");

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => TransaksiPengiriman.fromJson(item)).toList();
    } else {
      throw Exception("Gagal memuat pengiriman");
    }
  }

  static Future<void> updateStatus(int idTransaksi, String status) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: "token");

    final response = await http.patch(
      Uri.parse('http://10.0.2.2:8000/api/kurir/pengiriman/$idTransaksi/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengupdate status");
    }
  }
}
