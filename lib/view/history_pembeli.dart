import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiwayatTransaksiPembelian extends StatefulWidget {
  const RiwayatTransaksiPembelian({super.key});

  @override
  State<RiwayatTransaksiPembelian> createState() => _RiwayatTransaksiPembelianState();
}

class _RiwayatTransaksiPembelianState extends State<RiwayatTransaksiPembelian> {
  final storage = FlutterSecureStorage();
  List<dynamic> transaksi = [];
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/pembeli/transaksi'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => transaksi = data);
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
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        backgroundColor: const Color(0xFF005E34),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: selectDateRange,
          )
        ],
      ),
      body: filteredTransaksi.isEmpty
          ? const Center(child: Text("Tidak ada transaksi."))
          : ListView.builder(
              itemCount: filteredTransaksi.length,
              itemBuilder: (context, index) {
                final tx = filteredTransaksi[index];
                return ListTile(
                  title: Text("Nota: ${tx['id_transaksi']} - ${tx['status_transaksi']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tanggal: ${format.format(DateTime.parse(tx['tanggal_pesan']))}\nTotal: Rp ${tx['total_harga']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailTransaksiPembelian(idTransaksi: tx['id_transaksi']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DetailTransaksiPembelian extends StatelessWidget {
  final int idTransaksi;
  const DetailTransaksiPembelian({super.key, required this.idTransaksi});

  @override
  Widget build(BuildContext context) {
    // Dummy page
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        backgroundColor: const Color(0xFF005E34),
      ),
      body: Center(
        child: Text("Detail transaksi ID: $idTransaksi"),
      ),
    );
  }
}
