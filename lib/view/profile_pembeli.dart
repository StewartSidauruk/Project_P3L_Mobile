import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ✅ 1. Impor file yang dibutuhkan untuk logout
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/view/login.dart';

class ProfilePembeli extends StatefulWidget {
  const ProfilePembeli({super.key});

  @override
  State<ProfilePembeli> createState() => _ProfilePembeliState();
}

class _ProfilePembeliState extends State<ProfilePembeli> {
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
      final data = json.decode(response.body);
      if (data['role'] == 'Pembeli') {
        setState(() => user = data['user']);
      }
    } else {
      print("Gagal mengambil data pembeli: ${response.body}");
    }
  }

  // ✅ 2. Menggunakan fungsi _logout yang standar dari AuthService
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
  
  // ✅ Fungsi untuk menampilkan dialog konfirmasi
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              _logout(context); // Panggil fungsi logout
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005E34),
        title: const Text("Profil", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset("images/fox-avatar.png", width: 80, height: 80),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nama", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?['nama_pembeli'] ?? ''),
                        const SizedBox(height: 8),
                        const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?['email_pembeli'] ?? ''),
                        const SizedBox(height: 8),
                        const Text("Nomor HP", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?['telp_pembeli'] ?? ''),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildBox(
            title: 'Alamat',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: user?['alamat'] == null || (user?['alamat'] as List).isEmpty
                  ? [const Text("Belum ada alamat.")]
                  : (user?['alamat'] as List).map<Widget>((alamat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(alamat['alamat'] ?? '-'),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          _buildBox(
            title: 'Poin Reward 🪙',
            content: Text(
              user?['poin_pembeli'].toString() ?? '0',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ✅ 3. Menambahkan Tombol Logout di body
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _showLogoutDialog, // Panggil fungsi dialog yang sama
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}