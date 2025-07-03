// lib/view/detail_barang_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // TAMBAHKAN: Pastikan impor ini ada

// Gunakan formatter yang sama dari home_pembeli
final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

class DetailBarangView extends StatefulWidget {
  final Map<String, dynamic> barang;
  const DetailBarangView({super.key, required this.barang});

  @override
  State<DetailBarangView> createState() => _DetailBarangViewState();
}

class _DetailBarangViewState extends State<DetailBarangView> {
  late String _mainImageUrl;
  final List<String> _imageUrls = [];
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.barang['images'] != null && (widget.barang['images'] as List).isNotEmpty) {
      for (var image in widget.barang['images']) {
        final fileName = Uri.encodeComponent(image['directory']);
        _imageUrls.add('https://projectp3l-production.up.railway.app/gambarBarang/$fileName');
      }
      _mainImageUrl = _imageUrls.first;
    } else {
      _mainImageUrl = 'https://via.placeholder.com/400?text=No+Image';
    }
  }

  void _switchImage(int index) {
    setState(() {
      _mainImageUrl = _imageUrls[index];
      _selectedImageIndex = index;
    });
  }

Widget _buildInfoWidget({required String text, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Agar container tidak memenuhi lebar layar
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // TAMBAHKAN: Widget baru untuk status garansi
  Widget _buildWarrantyStatus(String? garansiString) {
    // 1. Cek jika data garansi tidak ada (null atau string kosong).
    if (garansiString == null || garansiString.isEmpty) {
      return _buildInfoWidget(
        text: 'Barang Ini Tidak Memiliki Garansi',
        icon: Icons.gpp_maybe_outlined, // Icon netral untuk status "tidak ada"
        color: Colors.grey.shade700,
      );
    }

    // 2. Coba parse tanggal dari string. Jika format salah, tampilkan pesan error.
    final garansiDate = DateTime.tryParse(garansiString);
    if (garansiDate == null) {
      return _buildInfoWidget(
        text: 'Informasi Garansi Tidak Valid',
        icon: Icons.error_outline,
        color: Colors.orange.shade800,
      );
    }

    // 3. Bandingkan tanggal garansi dengan tanggal hari ini.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final warrantyDay = DateTime(garansiDate.year, garansiDate.month, garansiDate.day);
    final bool isExpired = warrantyDay.isBefore(today);

    // 4. Siapkan teks, warna, dan ikon berdasarkan status garansi.
    final formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(garansiDate);
    final Color badgeColor = isExpired ? Colors.red.shade700 : Colors.green.shade700;
    final String statusText = isExpired ? 'Garansi telah habis pada' : 'Garansi berlaku hingga';
    final IconData icon = isExpired ? Icons.gpp_bad_outlined : Icons.verified_user_outlined;

    // 5. Kembalikan widget untuk status garansi yang valid.
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: badgeColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: badgeColor, fontSize: 14),
                  children: [
                    TextSpan(text: '$statusText '),
                    TextSpan(
                      text: formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final String namaBarang = widget.barang['nama_barang'] ?? 'Nama Barang Tidak Tersedia';
    final num hargaBarang = widget.barang['harga_barang'] ?? 0;
    final String deskripsi = widget.barang['deskripsi_barang'] ?? 'Deskripsi tidak tersedia.';
    final String namaPenitip = widget.barang['penitip']?['nama_penitip'] ?? 'Penitip Anonim';
    final num ratingPenitip = widget.barang['penitip']?['rating_penitip'] ?? 0.0;
    
    // MODIFIKASI: Ambil data garansi dari widget.barang
    final String? garansiString = widget.barang['garansi'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF005E34),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaBarang,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(hargaBarang),
                    style: const TextStyle(
                      color: Color(0xFF005E34),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // MODIFIKASI: Panggil widget status garansi di sini
                  _buildWarrantyStatus(garansiString),

                  const SizedBox(height: 16),
                  _buildSellerInfo(namaPenitip, ratingPenitip),
                  const Divider(height: 32, thickness: 1),
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deskripsi,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildPurchaseNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Widget _buildImageGallery, _buildSellerInfo, dan _buildPurchaseNote tetap sama)
  Widget _buildImageGallery() {
    // ... (tidak ada perubahan)
    return Column(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[200],
          child: Image.network(
            _mainImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        if (_imageUrls.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final bool isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => _switchImage(index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF005E34) : Colors.grey.shade300,
                        width: 2.5,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(_imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSellerInfo(String name, num rating) {
    // ... (tidak ada perubahan)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.storefront, color: Colors.grey[700], size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(' (Rating Penjual)', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseNote() {
    // ... (tidak ada perubahan)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF005E34).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF005E34)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, color: Color(0xFF005E34)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Beli di website reusemart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF005E34),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}