import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/services/top_seller_service.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class TopSellerView extends StatefulWidget {
  const TopSellerView({super.key});

  @override
  State<TopSellerView> createState() => _TopSellerViewState();
}

class _TopSellerViewState extends State<TopSellerView> {
  // State untuk menyimpan data Future dan periode yang dipilih
  Future<List<dynamic>>? _topSellersFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Memuat data untuk pertama kali dengan periode saat ini
    _fetchData();
  }

  // Fungsi untuk memuat atau memuat ulang data dari server
  void _fetchData() {
    setState(() {
      _topSellersFuture = TopSellerService.fetchTopSellers(_selectedDate);
    });
  }

  // Fungsi untuk menampilkan dialog pemilih bulan & tahun
  void _pickMonth(BuildContext context) {
    showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      // ✅ HAPUS BARIS DI BAWAH INI:
      // locale: const Locale('id', 'ID'), 
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedDate = date;
        });
        _fetchData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format periode untuk ditampilkan di AppBar
    final formattedPeriode = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Seller', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005E34),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: Container(
            color: const Color(0xFF004B2B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedPeriode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  onPressed: () => _pickMonth(context),
                  tooltip: 'Pilih Periode',
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _topSellersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada Top Seller pada periode ini.'));
          }

          final topSellers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: topSellers.length,
            itemBuilder: (context, index) {
              final seller = topSellers[index];
              return _buildTopSellerCard(seller, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildTopSellerCard(Map<String, dynamic> seller, int rank) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final totalPenjualan =
        double.tryParse(seller['total_penjualan'].toString()) ?? 0.0;

    // Tentukan warna border berdasarkan peringkat
    Color borderColor = Colors.transparent;
    if (rank == 1) borderColor = Colors.amber.shade700;
    if (rank == 2) borderColor = Colors.grey.shade500;
    if (rank == 3) borderColor = Colors.brown.shade400;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ranking
            Text(
              '#$rank',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.amber.shade800 : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 16),
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seller['nama_penitip'] ?? 'Tanpa Nama',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tampilkan pesan berbeda jika tidak ada penjualan
                  totalPenjualan > 0
                      ? Text(
                          'Total Penjualan: ${currencyFormatter.format(totalPenjualan)}',
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        )
                      : Text(
                          'Belum ada penjualan di periode ini',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                ],
              ),
            ),
            // Tampilkan badge hanya untuk rank 1 dan jika ada penjualan
            if (rank == 1 && totalPenjualan > 0)
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade800,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}