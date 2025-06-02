import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';

class HomePenitip extends StatefulWidget {
  const HomePenitip({super.key});

  @override
  State<HomePenitip> createState() => _HomePenitipState();
}

class _HomePenitipState extends State<HomePenitip> {
  int _selectedIndex = 0;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    NotifikasiService.fetchNotifikasi().then((data) {
      setState(() {
        _notifications = data;
      });
    });
  }

  Future<void> _logout(BuildContext context) async {
    final storage = FlutterSecureStorage();
    await storage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  final List<Widget> _pages = [
    const Center(child: Text("Beranda Penitip")),
    const Center(child: Text("Daftar Barang")),
    const Center(child: Text("Profil")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        selectedItemColor: const Color(0xFF005E34),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Barang'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF005E34),
      title: _buildSearchBar(),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Notifikasi"),
                content: _notifications.isEmpty
                    ? const Text("Tidak ada notifikasi saat ini.")
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _notifications.map((notif) => ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(notif),
                        )).toList(),
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari barang...',
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
