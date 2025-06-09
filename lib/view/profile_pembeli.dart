import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _logout() async {
    final token = await storage.read(key: 'token');
    await http.post(
      Uri.parse('http://10.0.2.2:8000/api/pembeli/logout-mobile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await storage.deleteAll();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin logout?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
            color: Colors.white,
          ),
        ],
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
                      child: Text(alamat['alamat'] ?? '-'), // GANTI INI
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
