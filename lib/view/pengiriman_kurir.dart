import 'package:flutter/material.dart';
import '../model/transaksi_pengiriman.dart';
import '../services/pengiriman_service.dart';

class PengirimanKurirPage extends StatefulWidget {
  const PengirimanKurirPage({super.key});

  @override
  State<PengirimanKurirPage> createState() => _PengirimanKurirPageState();
}

class _PengirimanKurirPageState extends State<PengirimanKurirPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TransaksiPengiriman>> _futurePengiriman;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _futurePengiriman = PengirimanService.fetchPengiriman();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cari kiriman anda", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005E34),
        actions: const [
          Icon(Icons.notifications_none),
          Icon(Icons.logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Pengantaran"),
            Tab(text: "Selesaikan"),
            Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: FutureBuilder<List<TransaksiPengiriman>>(
        future: _futurePengiriman,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ ${snapshot.error}'));
          } else {
            final all = snapshot.data!;
            final disiapkan = all.where((t) => t.status == 'disiapkan').toList();
            final dikirim = all.where((t) => t.status == 'dikirim').toList();
            final selesai = all.where((t) => t.status == 'selesai').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(disiapkan, "Kirim", Colors.amber),
                _buildList(dikirim, "selesai", Colors.green),
                _buildList(selesai, null, null),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildList(List<TransaksiPengiriman> data, String? buttonLabel, Color? buttonColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final transaksi = data[index];
        final barang = transaksi.barangs.first;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(transaksi.tanggal),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaksi.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _capitalize(transaksi.status),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("Nomor: ${transaksi.nota}"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox( 
                      width: 70, 
                      height: 70, 
                      child: Image.network(
                        barang.gambar ?? 'https://via.placeholder.com/70',
                        fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey, size: 70), // Ukuran ikon error
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(barang.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(transaksi.pembeli),
                          const SizedBox(height: 4),
                          Text("Rp ${barang.harga}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ("Rp ${barang.harga}"),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Alamat :   ${transaksi.alamat}"),
                const SizedBox(height: 8),
                if (buttonLabel != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final statusBaru = transaksi.status == 'disiapkan' ? 'dikirim' : 'selesai';

                        try {
                          await PengirimanService.updateStatus(transaksi.id, statusBaru);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ Status diperbarui ke $statusBaru')),
                          );

                          setState(() {
                            _futurePengiriman = PengirimanService.fetchPengiriman();
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❌ Gagal update status')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                      child: Text(buttonLabel),
                    ),

                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "disiapkan":
        return Colors.red;
      case "dikirim":
        return Colors.amber;
      case "selesai":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String input) =>
      input.isNotEmpty ? input[0].toUpperCase() + input.substring(1) : '';
} 
