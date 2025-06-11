// lib/view/profile_penitip.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/view/login.dart';

class ProfilePenitip extends StatefulWidget {
  const ProfilePenitip({super.key});

  @override
  State<ProfilePenitip> createState() => _ProfilePenitipState();
}

class _ProfilePenitipState extends State<ProfilePenitip> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (mounted) setState(() => user = jsonData['user']);
      }
    } catch (e) {
      print("Gagal fetch profile: $e");
    }
  }

  // === TAMBAHKAN: Fungsi logout dari AuthService ===
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
  // =================================================

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildStatsCards(currency),
                  const SizedBox(height: 20),
                  // === TAMBAHKAN: Tombol Logout ===
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: _showLogoutDialog,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // ===============================
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 35, backgroundImage: AssetImage('images/fox-avatar.png')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user!['nama_penitip'] ?? 'Nama tidak tersedia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(user!['email_penitip'] ?? '-', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(user!['telp_penitip'] ?? '-', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(NumberFormat currency) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildStatCard("Poin Reward 🪙", "${user!['poin_penitip'] ?? 0}")),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard("Saldo 💸", currency.format(user!['saldo'] ?? 0))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF005E34))),
          ],
        ),
      ),
    );
  }
}