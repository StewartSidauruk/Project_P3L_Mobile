import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // ganti jika perlu

  static Future<List<dynamic>> fetchBarang() async {
    final response = await http.get(Uri.parse('$baseUrl/barang'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data barang');
    }
  }

  static Future<List<dynamic>> fetchKategori() async {
    final response = await http.get(Uri.parse('$baseUrl/kategori'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat kategori');
    }
  }
}
