// lib/view/home_hunter.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/services/home_service.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:flutter_application_p3l/view/detail_barang_view.dart';
import 'package:flutter_application_p3l/view/komisi_hunter.dart';
import 'package:flutter_application_p3l/view/profile_hunter.dart';
import 'package:flutter_application_p3l/view/top_seller_view.dart';
import 'package:intl/intl.dart';

// --- DIKEMBALIKAN: Import yang diperlukan untuk Notifikasi ---
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// -------------------------------------------------------------

final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
enum SortOption { none, priceAsc, priceDesc }

// --- DIKEMBALIKAN: Inisialisasi plugin notifikasi ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// ---------------------------------------------------

class HomeHunter extends StatefulWidget {
  const HomeHunter({super.key});

  @override
  State<HomeHunter> createState() => _HomeHunterState();
}

class _HomeHunterState extends State<HomeHunter> {
  int _selectedIndex = 0;
  List<String> _notifications = [];

  List<dynamic> kategori = [];
  List<dynamic> _allBarang = [];
  List<dynamic> _filteredBarang = [];
  final TextEditingController _searchController = TextEditingController();
  int? _selectedKategoriId;
  SortOption _currentSortOption = SortOption.none;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp(); // Panggil _initApp yang sekarang berisi semua setup
  }

  // --- DIKEMBALIKAN: Seluruh fungsi setup notifikasi ---
  Future<void> _initApp() async {
    // 1. Setup notifikasi lokal
    await initLocalNotifications();

    // 2. Setup listener dari Firebase Messaging
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String? title = message.notification?.title ?? message.data['title'];
      String? body = message.notification?.body ?? message.data['body'];

      if (title != null && body != null) {
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

    // 3. Load data utama dan tambahkan listener search bar
    await loadHomeData();
    _searchController.addListener(_filterAndSortBarang);
  }

  Future<void> initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 'Notifikasi Penting',
      description: 'Channel untuk notifikasi penting', importance: Importance.high,
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  // ----------------------------------------------------

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    try {
      final data = await NotifikasiService.fetchNotifikasi();
      if (mounted) setState(() => _notifications = data);
    } catch (e) {
      print("Gagal mengambil notifikasi: $e");
    }
  }

  Future<void> loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      final kategoriRes = await HomeService.fetchKategori();
      final barangRes = await HomeService.fetchBarang();
      if (mounted) {
        setState(() {
          kategori = kategoriRes;
          _allBarang = barangRes;
          _filteredBarang = barangRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Gagal load data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAndSortBarang() {
    List<dynamic> tempBarang = List.from(_allBarang);
    if (_searchController.text.isNotEmpty) {
      String query = _searchController.text.toLowerCase();
      tempBarang = tempBarang.where((barang) {
        return barang['nama_barang'].toString().toLowerCase().contains(query);
      }).toList();
    }
    if (_selectedKategoriId != null) {
      tempBarang = tempBarang.where((barang) {
        return barang['id_kategori'] == _selectedKategoriId;
      }).toList();
    }
    switch (_currentSortOption) {
      case SortOption.priceAsc:
        tempBarang.sort((a, b) => a['harga_barang'].compareTo(b['harga_barang']));
        break;
      case SortOption.priceDesc:
        tempBarang.sort((a, b) => b['harga_barang'].compareTo(a['harga_barang']));
        break;
      case SortOption.none:
        break;
    }
    setState(() => _filteredBarang = tempBarang);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBeranda(),
      KomisiHunter(),
      const ProfileHunter(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading && _selectedIndex == 0
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF005E34),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Komisi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_selectedIndex != 0) {
      return AppBar(
        title: Text(
          _selectedIndex == 1 ? 'Komisi Saya' : 'Profil Hunter',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF005E34),
        automaticallyImplyLeading: false,
      );
    }
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
                    ? const Text("Tidak ada notifikasi.")
                    : SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) => ListTile(
                              leading: const Icon(Icons.notifications), title: Text(_notifications[index])),
                        ),
                      ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined, color: Colors.white),
          tooltip: 'Top Seller',
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TopSellerView())),
        ),
      ],
    );
  }

  // ... (Sisa kode widget builder tidak ada perubahan dan sudah benar)
  Widget _buildBeranda() {
    return RefreshIndicator(
      onRefresh: loadHomeData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
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
          _buildSortButtons(),
          const SizedBox(height: 20),
          const Text('Semua Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildBarangGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari di Reusemart...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
              : null,
        ),
      ),
    );
  }

  Widget _carouselItem(String imagePath) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
      );

  Widget _buildSortButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_upward),
            label: const Text("Harga Terendah"),
            onPressed: () {
              setState(() => _currentSortOption = SortOption.priceAsc);
              _filterAndSortBarang();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _currentSortOption == SortOption.priceAsc ? Colors.white : const Color(0xFF005E34),
              backgroundColor: _currentSortOption == SortOption.priceAsc ? const Color(0xFF005E34) : Colors.transparent,
              side: const BorderSide(color: Color(0xFF005E34)),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_downward),
            label: const Text("Harga Tertinggi"),
            onPressed: () {
              setState(() => _currentSortOption = SortOption.priceDesc);
              _filterAndSortBarang();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _currentSortOption == SortOption.priceDesc ? Colors.white : const Color(0xFF005E34),
              backgroundColor: _currentSortOption == SortOption.priceDesc ? const Color(0xFF005E34) : Colors.transparent,
              side: const BorderSide(color: Color(0xFF005E34)),
            ),
          ),
        ],
      );

  Widget _buildKategoriList() => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: kategori.length,
          itemBuilder: (context, index) {
            final item = kategori[index];
            final imageUrl = 'https://projectp3l-production.up.railway.app/images/${Uri.encodeComponent(item['gambar'])}';
            final bool isSelected = _selectedKategoriId == item['id_kategori'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedKategoriId = isSelected ? null : item['id_kategori']);
                _filterAndSortBarang();
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF005E34) : const Color(0xFFE1DDD2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.white : Colors.green.shade700, width: 1.5),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Image.network(imageUrl, fit: BoxFit.contain)),
                    const SizedBox(height: 5),
                    Text(item['kategori'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildBarangGrid() {
    if (_filteredBarang.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Barang tidak ditemukan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredBarang.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final item = _filteredBarang[index];
        final imageUrl = (item['images'] != null && (item['images'] as List).isNotEmpty)
            ? 'https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(item['images'][0]['directory'])}'
            : 'https://via.placeholder.com/160?text=No+Image';
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailBarangView(barang: item))),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover))),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['nama_barang'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(formatter.format(item['harga_barang']), style: const TextStyle(color: Color(0xFF005E34), fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}