import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart'; // pastikan file login kamu diekspor dengan benar

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _logout(BuildContext context) async {
    final storage = FlutterSecureStorage();

    await storage.delete(key: 'token');
    await storage.delete(key: 'role'); // jika kamu menyimpan role juga

    // Navigasi ke halaman login dan hapus semua riwayat sebelumnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF113C23),
      body: const Center(
        child: Text(
          'Selamat datang di halaman Home!',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
