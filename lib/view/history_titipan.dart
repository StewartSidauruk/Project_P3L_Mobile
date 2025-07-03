import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/services/penitip_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class RiwayatPenitipanView extends StatefulWidget {
  const RiwayatPenitipanView({super.key});

  @override
  State<RiwayatPenitipanView> createState() => _RiwayatPenitipanViewState();
}

class _RiwayatPenitipanViewState extends State<RiwayatPenitipanView> {
  late Future<List<dynamic>> _riwayatFuture;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  void _loadRiwayat() {
    setState(() {
      _riwayatFuture = PenitipService.fetchRiwayatPenitipan();
    });
  }

  // ✅ FUNGSI BARU: Untuk menghitung sisa hari
  String _hitungSisaHari(String? tanggalAkhirStr) {
    if (tanggalAkhirStr == null) return 'Tidak ada batas';
    
    final tanggalAkhir = DateTime.parse(tanggalAkhirStr);
    final hariIni = DateTime.now();
    // Mengabaikan komponen jam, menit, detik untuk perbandingan hari yang akurat
    final selisih = tanggalAkhir.difference(DateTime(hariIni.year, hariIni.month, hariIni.day)).inDays;

    if (selisih < 0) {
      return 'Telah berakhir';
    } else if (selisih == 0) {
      return 'Berakhir hari ini';
    } else {
      return 'Sisa $selisih hari';
    }
  }

  // ✅ FUNGSI BARU: Untuk mendapatkan warna berdasarkan sisa hari
  Color _getWarnaSisaHari(String? tanggalAkhirStr) {
    if (tanggalAkhirStr == null) return Colors.grey;

    final tanggalAkhir = DateTime.parse(tanggalAkhirStr);
    final hariIni = DateTime.now();
    final selisih = tanggalAkhir.difference(DateTime(hariIni.year, hariIni.month, hariIni.day)).inDays;

    if (selisih < 1) {
      return Colors.red.shade700; // Merah untuk hari ini atau sudah lewat
    } else if (selisih <= 7) {
      return Colors.orange.shade700; // Oranye untuk 1-7 hari
    } else {
      return Colors.green.shade700; // Hijau jika masih lama
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async => _loadRiwayat(),
        child: FutureBuilder<List<dynamic>>(
          future: _riwayatFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada riwayat penitipan.'));
            }

            final riwayatList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final transaksi = riwayatList[index];
                final isExpanded = _expandedId == transaksi['id_transaksi_penitipan'].toString();
                return _buildTransaksiCard(transaksi, isExpanded);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(Map<String, dynamic> transaksi, bool isExpanded) {
    final detailList = transaksi['detail_penitipan'] as List;
    if (detailList.isEmpty) return const SizedBox.shrink();

    final idTransaksi = transaksi['id_transaksi_penitipan'].toString();
    final firstBarang = detailList.first['barang'];
    final imageUrl = firstBarang['images'].isNotEmpty
        ? 'https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(firstBarang['images'][0]['directory'])}'
        : null;
    
    final tanggal = DateTime.parse(transaksi['tanggal_transaksi']);
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(tanggal);

    // ✅ Logika Baru: Cari tanggal akhir terdekat dari semua barang di transaksi ini
    DateTime? nearestExpiryDate;
    for (var detail in detailList) {
      if (detail['barang']['tanggal_akhir'] != null) {
        final expiry = DateTime.parse(detail['barang']['tanggal_akhir']);
        if (nearestExpiryDate == null || expiry.isBefore(nearestExpiryDate)) {
          nearestExpiryDate = expiry;
        }
      }
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.black54, size: 24),
                const SizedBox(width: 8),
                const Text('Penitipan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                // ✅ CHIP BARU: Menampilkan sisa masa titipan terdekat
                if (nearestExpiryDate != null)
                  Chip(
                    label: Text(
                      _hitungSisaHari(nearestExpiryDate.toIso8601String()),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
                    ),
                    backgroundColor: _getWarnaSisaHari(nearestExpiryDate.toIso8601String()),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                const SizedBox(width: 6),
                Chip(
                  label: Text(transaksi['status'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: _getStatusColor(transaksi['status']),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Divider(height: 24),

            // Konten Barang (tetap sama)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 60))
                      : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.inventory)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstBarang['nama_barang'] ?? 'Nama Barang Tidak Tersedia',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detailList.length > 1
                            ? '${detailList.length} barang'
                            : '1 barang',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildDetailSection(detailList), // Konten detail
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            
            const Divider(height: 24),

            // Footer Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Harga Titip', style: TextStyle(color: Colors.grey)),
                    Text(
                      currencyFormatter.format(transaksi['total_harga'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _expandedId = isExpanded ? null : idTransaksi;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpanded ? Colors.grey[600] : const Color(0xFF005E34),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isExpanded ? 'Tutup Detail' : 'Lihat Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(List<dynamic> detailList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20, thickness: 1),
        const Text(
          'Rincian Barang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...detailList.map((detail) {
          final barang = detail['barang'];
          final sisaHariText = _hitungSisaHari(barang['tanggal_akhir']);
          final sisaHariColor = _getWarnaSisaHari(barang['tanggal_akhir']);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang['nama_barang'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      // ✅ Teks sisa hari per barang
                      Text(
                        sisaHariText,
                        style: TextStyle(fontSize: 12, color: sisaHariColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormatter.format(barang['harga_barang'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'dititipkan':
        return Colors.blue;
      case 'terjual':
        return Colors.green;
      case 'diambil':
        return Colors.orange;
      case 'didonasikan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}