import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_p3l/view/profile_penitip.dart';
import 'package:flutter_application_p3l/services/home_service.dart';
import 'package:intl/intl.dart';

import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:flutter_application_p3l/auth/auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
List<dynamic> kategori = [];
List<dynamic> barang = [];

class HomePenitip extends StatefulWidget {
  const HomePenitip({super.key});

  @override
  State<HomePenitip> createState() => _HomePenitipState();
}

class _HomePenitipState extends State<HomePenitip> {
  int _selectedIndex = 0;
  List<String> _notifications = [];

  Future<void> _refreshNotifications() async {
    final data = await NotifikasiService.fetchNotifikasi();
    setState(() {
      _notifications = data;
    });
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> loadHomeData() async {
    try {
      final kategoriRes = await HomeService.fetchKategori();
      final barangRes = await HomeService.fetchBarang();
      setState(() {
        kategori = kategoriRes;
        barang = barangRes;
      });
    } catch (e) {
      print('❌ Gagal load data: $e');
    }
  }

  Future<void> initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifikasi Penting',
      description: 'Channel untuk notifikasi penting',
      importance: Importance.high,
    );

    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void initState() {
    super.initState();
    _initApp();
    loadHomeData(); // tambahkan ini
  }

Future<void> _initApp() async {
  // Tidak perlu permission di API 27
  await initLocalNotifications();

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔥 FCM diterima: ${message.toMap()}');

    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];

    if (title != null && body != null) {
      print('📣 Memunculkan notifikasi tray');

      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notifikasi Penting',
            channelDescription: 'Channel untuk notifikasi penting',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });
}



  Future<void> _logout(BuildContext context) async {
    await AuthService.logout(); // ✅ panggil method dari auth.dart
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildBeranda(), // 🟢 Tampilkan info umum seperti pembeli
      const Center(child: Text("Daftar Barang")),
      const ProfilePenitip(),
    ];

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
          onPressed: () async {
            await _refreshNotifications();
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

  Widget _buildBeranda() {
  return RefreshIndicator(
    onRefresh: loadHomeData,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 3 / 1,
          child: PageView(
            children: [
              _carouselItem('images/banner1.jpg'),
              _carouselItem('images/banner2.jpg'),
              _carouselItem('images/banner3.jpg'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildKategoriList(),
        const SizedBox(height: 20),
        const Text('Rekomendasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildBarangGrid(),
      ],
    ),
  );
}

Widget _carouselItem(String imagePath) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
    ),
  );
}

Widget _buildKategoriList() {
  return SizedBox(
    height: 100,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: kategori.length,
      itemBuilder: (context, index) {
        final item = kategori[index];
        final imageUrl = 'http://10.0.2.2:8000/images/${Uri.encodeComponent(item['gambar'])}';

        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE1DDD2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade700, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(item['kategori'], style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildBarangGrid() {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: barang.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final item = barang[index];
        final fileName = Uri.encodeComponent(item['images'][0]['directory']);
        final imageUrl = 'http://10.0.2.2:8000/gambarBarang/$fileName';

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['nama_barang'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  formatter.format(item['harga_barang']),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
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