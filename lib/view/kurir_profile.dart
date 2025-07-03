import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/view/login.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import '../model/kurir.dart';
import '../services/kurir_service.dart';

class KurirProfilePage extends StatefulWidget {
  const KurirProfilePage({super.key});

  @override
  State<KurirProfilePage> createState() => _KurirProfilePageState();
}

class _KurirProfilePageState extends State<KurirProfilePage> {
  late Future<Kurir> _kurirFuture;

  @override
  void initState() {
    super.initState();
    _kurirFuture = KurirService.fetchProfil();
  }

  Future<void> _logout() async {
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
              _logout();
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
      body: FutureBuilder<Kurir>(
        future: _kurirFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ ${snapshot.error}'));
          } else {
            final kurir = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final refreshed = await KurirService.fetchProfil();
                setState(() => _kurirFuture = Future.value(refreshed));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kartu Profil
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset("images/profilKurir.png", width: 80, height: 80),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Nama", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(kurir.nama),
                                const SizedBox(height: 8),
                                Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(kurir.email),
                                const SizedBox(height: 8),
                                Text("Nomor HP", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(kurir.telp),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tombol Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: _showLogoutDialog,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
