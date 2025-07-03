import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Halaman utama untuk menampilkan daftar riwayat transaksi
class RiwayatTransaksiPembelian extends StatefulWidget {
  const RiwayatTransaksiPembelian({super.key});

  @override
  State<RiwayatTransaksiPembelian> createState() =>
      _RiwayatTransaksiPembelianState();
}

class _RiwayatTransaksiPembelianState extends State<RiwayatTransaksiPembelian> {
  final storage = const FlutterSecureStorage();
  List<dynamic> transaksi = [];
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://projectp3l-production.up.railway.app/api/pembeli/transaksi'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => transaksi = data);
      }
    } catch (e) {
      // Handle error, misalnya dengan menampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get filteredTransaksi {
    if (startDate == null || endDate == null) return transaksi;
    return transaksi.where((tx) {
      final tgl = DateTime.parse(tx['tanggal_pesan']);
      return tgl.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          tgl.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Widget buildTransaksiCard(Map<String, dynamic> tx) {
    // ... (Fungsi buildTransaksiCard Anda yang sudah ada, dengan sedikit modifikasi)
    final tgl = DateTime.parse(tx['tanggal_pesan']);
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final firstDetail =
        tx['detail_transaksi'].isNotEmpty ? tx['detail_transaksi'][0] : null;
    final barang = firstDetail != null ? firstDetail['barang'] : null;
    final images = barang?['images'] ?? [];
    final gambar = images.isNotEmpty ? images[0]['directory'] : null;
    final status = tx['status_transaksi'] as String? ?? 'Tidak Diketahui';

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final totalHarga = num.tryParse(tx['total_harga'].toString()) ?? 0;
    final formattedTotalHarga = currencyFormatter.format(totalHarga);

    Color statusColor;
    Color statusBackgroundColor;

    switch (status.toLowerCase()) {
      case 'selesai':
        statusColor = Colors.green.shade800;
        statusBackgroundColor = Colors.green.shade100;
        break;
      case 'dikirim':
        statusColor = Colors.blue.shade800;
        statusBackgroundColor = Colors.blue.shade100;
        break;
      case 'disiapkan':
        statusColor = Colors.orange.shade800;
        statusBackgroundColor = Colors.orange.shade100;
        break;
      case 'dibatalkan':
        statusColor = Colors.red.shade800;
        statusBackgroundColor = Colors.red.shade100;
        break;
      default:
        statusColor = Colors.grey.shade800;
        statusBackgroundColor = Colors.grey.shade200;
    }

    final displayText = status[0].toUpperCase() + status.substring(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shopping_bag_outlined, color: Colors.black54),
                    SizedBox(width: 8),
                    Text("Belanja",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatter.format(tgl),
                style: const TextStyle(color: Colors.grey)),
            const Divider(height: 20),
            Row(
              children: [
                if (gambar != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(gambar)}",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                    ),
                  )
                else
                  const Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang?['nama_barang'] ?? "Barang tidak ditemukan",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("${tx['detail_transaksi'].length} barang",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Belanja:\n$formattedTotalHarga",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ElevatedButton(
                  onPressed: () {
                    // --- NAVIGASI KE HALAMAN DETAIL ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailTransaksiPembelian(transaksi: tx),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005E34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )),
                  child: const Text(
                    "Lihat Detail",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005E34),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: selectDateRange,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTransaksi.isEmpty
              ? const Center(child: Text("Tidak ada transaksi dalam rentang tanggal ini."))
              : RefreshIndicator(
                  onRefresh: fetchTransaksi,
                  child: ListView.builder(
                    itemCount: filteredTransaksi.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransaksi[index];
                      return buildTransaksiCard(tx);
                    },
                  ),
                ),
    );
  }
}

// =======================================================================
// WIDGET BARU: HALAMAN DETAIL TRANSAKSI
// =======================================================================
class DetailTransaksiPembelian extends StatelessWidget {
  final Map<String, dynamic> transaksi;

  const DetailTransaksiPembelian({super.key, required this.transaksi});

  // Helper untuk format tanggal
  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  // Helper untuk format mata uang
  String _formatCurrency(dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(number);
  }

  @override
  Widget build(BuildContext context) {
    final status = transaksi['status_transaksi'] as String? ?? 'Tidak Diketahui';
    final displayText = status[0].toUpperCase() + status.substring(1);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005E34),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- KARTU INFO PENGIRIMAN ---
          _buildSectionCard(
            title: 'Info Pengiriman',
            icon: Icons.local_shipping_outlined,
            children: [
              _buildInfoRow('Metode', transaksi['metode_pengiriman'] ?? '-'),
              _buildInfoRow('Alamat', transaksi['alamat_pengiriman'] ?? 'Tidak ada alamat.'),
            ],
          ),
          const SizedBox(height: 16),

          // --- KARTU RINCIAN PRODUK ---
          _buildSectionCard(
            title: 'Rincian Produk',
            icon: Icons.inventory_2_outlined,
            children: (transaksi['detail_transaksi'] as List<dynamic>)
                .map((detail) => _buildProductTile(detail))
                .toList(),
          ),
          const SizedBox(height: 16),

          // --- KARTU RINCIAN PEMBAYARAN ---
          _buildSectionCard(
            title: 'Rincian Pembayaran',
            icon: Icons.receipt_long_outlined,
            children: [
              _buildPaymentRow('Subtotal Produk', _formatCurrency(transaksi['total_harga_barang'])),
              _buildPaymentRow('Ongkos Kirim', _formatCurrency(transaksi['ongkos_kirim'])),
              _buildPaymentRow('Potongan Poin', "-${_formatCurrency(transaksi['potongan_poin'] * 100)}", isDiscount: true),
              const Divider(),
              _buildPaymentRow('Total Pembayaran', _formatCurrency(transaksi['total_harga']), isTotal: true),
            ],
          ),
          const SizedBox(height: 16),

           // --- KARTU INFO PESANAN ---
          _buildSectionCard(
            title: 'Informasi Pesanan',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('ID Transaksi', transaksi['id_transaksi'].toString()),
              _buildInfoRow('Status Pesanan', displayText),
              _buildInfoRow('Tgl. Pesan', _formatDate(transaksi['tanggal_pesan'])),
              _buildInfoRow('Tgl. Lunas', _formatDate(transaksi['tanggal_lunas'])),
              _buildInfoRow('Tgl. Kirim/Ambil', _formatDate(transaksi['tanggal_kirim_ambil'])),
            ],
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat satu kartu section
  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // Widget untuk menampilkan setiap produk
  Widget _buildProductTile(Map<String, dynamic> detail) {
    final barang = detail['barang'] as Map<String, dynamic>?;
    if (barang == null) return const SizedBox.shrink();

    final images = barang['images'] as List<dynamic>? ?? [];
    final gambarUrl = images.isNotEmpty
        ? "https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(images[0]['directory'])}"
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: gambarUrl != null
                ? Image.network(gambarUrl,
                    width: 60, height: 60, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported,
                    size: 60, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barang['nama_barang'] ?? 'Nama Produk Tidak Tersedia',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(barang['harga_barang']),
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk baris info biasa (misal: Alamat, Metode, dll)
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Lebar tetap untuk judul
            child: Text(title, style: TextStyle(color: Colors.grey[600])),
          ),
          const Text(' :  '),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // Widget untuk baris rincian pembayaran
  Widget _buildPaymentRow(String title, String value, {bool isTotal = false, bool isDiscount = false}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isDiscount ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}