import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'login.dart';

class HomeHunter extends StatefulWidget {
  const HomeHunter({super.key});

  @override
  State<HomeHunter> createState() => _HomeHunterState();
}

class _HomeHunterState extends State<HomeHunter> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text("Barang Titipan")),
    const Center(child: Text("Ambil & Donasi")),
    const Center(child: Text("Profil Hunter")),
  ];

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF005E34),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Titipan'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Donasi'),
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi belum tersedia')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi Logout'),
                content: const Text('Anda yakin ingin logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logout(context);
                    },
                    child: const Text('Logout'),
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
