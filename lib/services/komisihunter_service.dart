import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KomisiHunterService { // NAMA KELAS DIUBAH
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static final _storage = FlutterSecureStorage();

  //==================================================================
  // METODE UNTUK PROFIL / OTENTIKASI
  //==================================================================

  /// Mengambil profil user yang sedang login dan memverifikasi rolenya.
  static Future<Map<String, dynamic>> fetchProfileAsHunter() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('401');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['role'] == 'Pegawai' && (data['user']['jabatan']['role'] ?? '') == 'Hunter') {
          return data['user'];
        } else {
          throw Exception('Bukan Hunter'); 
        }
      } else {
        throw Exception(response.statusCode.toString());
      }
    } catch (e) {
      throw Exception('Error saat mengambil profil: ${e.toString()}');
    }
  }

  //==================================================================
  // METODE UNTUK KOMISI
  //==================================================================

  /// Mengambil daftar riwayat komisi untuk Hunter yang login.
  static Future<List<dynamic>> fetchKomisiHunterList() async {
    final token = await _storage.read(key: 'token');
     if (token == null) {
      throw Exception('401');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/komisi-hunter'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(response.statusCode.toString());
      }
    } catch (e) {
       throw Exception('Gagal memuat daftar komisi: ${e.toString()}');
    }
  }

  /// Mengambil detail spesifik dari satu komisi.
  static Future<Map<String, dynamic>> fetchKomisiHunterDetail(String idKomisi) async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('401');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/komisi-hunter/$idKomisi'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
         throw Exception(response.statusCode.toString());
      }
    } catch (e) {
      throw Exception('Gagal memuat detail komisi: ${e.toString()}');
    }
  }
}