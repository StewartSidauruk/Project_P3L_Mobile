// lib/view/profile_hunter.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/view/login.dart';
import 'package:intl/intl.dart';

class ProfileHunter extends StatefulWidget {
  const ProfileHunter({super.key});

  @override
  State<ProfileHunter> createState() => _ProfileHunterState();
}

class _ProfileHunterState extends State<ProfileHunter> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? user;
  int? totalKomisi;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await fetchProfile();
    if (user != null) {
      await fetchKomisi(user!['id_pegawai']);
    }
  }

  Future<void> fetchProfile() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://projectp3l-production.up.railway.app/api/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['role'] == 'Pegawai' && data['user']['jabatan']['role'] == 'Hunter') {
          setState(() => user = data['user']);
        }
      }
    } catch (e) {
      print("Gagal fetch profile hunter: $e");
    }
  }

  Future<void> fetchKomisi(String idPegawai) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://projectp3l-production.up.railway.app/api/me/komisi'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => totalKomisi = data['komisi_pegawai'] ?? 0);
      }
    } catch (e) {
      print("Gagal fetch komisi: $e");
      if (mounted) setState(() => totalKomisi = 0);
    }
  }

  // --- Fungsi untuk proses logout ---
  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  // --- TAMBAHKAN: Fungsi untuk menampilkan dialog konfirmasi ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // --- TAMBAHKAN: AppBar yang konsisten dengan halaman profil lain ---
      // -----------------------------------------------------------------
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card for Profile Information
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('images/fox-avatar.png'), // Pastikan path asset benar
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nama: ${user?['nama_pegawai'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Email: ${user?['email_pegawai'] ?? 'N/A'}"),
                        const SizedBox(height: 4),
                        Text("Nomor HP: ${user?['telp_pegawai'] ?? 'N/A'}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Komisi Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  const Text('Jumlah Komisi 🐝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  totalKomisi == null 
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                        formatter.format(totalKomisi ?? 0),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005E34),
                        ),
                      ),
                  const SizedBox(height: 8),
                  const Text('Ayo tingkatkan lagi ngulimu'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // --- TAMBAHKAN: ListTile untuk tombol Logout ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _showLogoutDialog, // Panggil dialog konfirmasi
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300)
            ),
          ),
          // ------------------------------------------------
        ],
      ),
    );
  }
}