import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TopSellerService {
  static const String _baseUrl = 'https://projectp3l-production.up.railway.app/api';

  // Fungsi diubah untuk menerima parameter tanggal
  static Future<List<dynamic>> fetchTopSellers(DateTime periode) async {
    // Format tanggal menjadi YYYY-MM untuk dikirim sebagai parameter
    final formattedPeriode = DateFormat('yyyy-MM').format(periode);
    final url = Uri.parse('$_baseUrl/top-sellers?periode=$formattedPeriode');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat data Top Seller: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}