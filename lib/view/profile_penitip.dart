import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfilePenitip extends StatefulWidget {
  const ProfilePenitip({super.key});

  @override
  State<ProfilePenitip> createState() => _ProfilePenitipState();
}

class _ProfilePenitipState extends State<ProfilePenitip> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() => user = jsonData['user']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundImage: AssetImage('images/fox-avatar.png'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Nama", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(user!['nama_penitip']),
                              const SizedBox(height: 8),
                              const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(user!['email_penitip']),
                              const SizedBox(height: 8),
                              const Text("Nomor HP", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(user!['telp_penitip']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // --- PERUBAHAN DIMULAI DI SINI ---
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text("Poin Reward 🪙", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  "${user!['poin_penitip'] ?? 0}",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Spacer(), // Menambahkan Spacer untuk mendorong teks ke bawah
                                const Text(
                                  "Unduh aplikasi untuk menukarkan poin dengan merchandise menarik!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text("Saldo 💸", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  currency.format(user!['saldo'] ?? 0),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Spacer(), // Menambahkan Spacer untuk mendorong teks ke bawah
                                const Text(
                                  "Ayo tingkatkan lagi penjualannya!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                // --- PERUBAHAN SELESAI DI SINI ---
              ],
            ),
    );
  }
}