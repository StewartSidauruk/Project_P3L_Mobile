import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Kurir>(
      future: _kurirFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('❌ ${snapshot.error}'));
        } else {
          final kurir = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text("Profil", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF005E34),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {}, // nanti kamu sambungkan dengan fungsi logout
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 190,
                width: double.infinity, // biar menempel kiri-kanan sesuai padding
                child: Card(
                  elevation: 4,
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
                              SizedBox(height: 8),
                              Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(kurir.email),
                              SizedBox(height: 8),
                              Text("Nomor HP", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(kurir.telp),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
