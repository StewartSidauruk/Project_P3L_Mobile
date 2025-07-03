import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/services/home_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_p3l/view/profile_pembeli.dart';
import 'package:flutter_application_p3l/view/list_merchandise.dart';
import 'package:flutter_application_p3l/view/history_pembeli.dart';
import 'package:flutter_application_p3l/view/top_seller_view.dart';
import 'package:flutter_application_p3l/view/detail_barang_view.dart';

final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ✅ ENUM UNTUK OPSI SORTIR
enum SortOption { none, priceAsc, priceDesc }

class HomePembeli extends StatefulWidget {
  const HomePembeli({super.key});

  @override
  State<HomePembeli> createState() => _HomePembeliState();
}

class _HomePembeliState extends State<HomePembeli> {
  int _selectedIndex = 0;
  List<String> _notifications = [];
  
  // ✅ STATE UNTUK FILTER DAN SORTIR
  List<dynamic> kategori = [];
  List<dynamic> _allBarang = []; // Menyimpan semua barang asli
  List<dynamic> _filteredBarang = []; // Menyimpan barang yang akan ditampilkan
  final TextEditingController _searchController = TextEditingController();
  int? _selectedKategoriId; // ID kategori yang dipilih
  SortOption _currentSortOption = SortOption.none; // Opsi sortir saat ini

  late final List<Widget> _pages;

  Future<void> _refreshNotifications() async {
    final data = await NotifikasiService.fetchNotifikasi();
    setState(() => _notifications = data);
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
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

  Future<void> _initApp() async {
    await initLocalNotifications();
    await loadHomeData();

    // Listener untuk pencarian real-time
    _searchController.addListener(_filterAndSortBarang);

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ... (logika FCM)
    });
    // ... (sisa logika FCM)
  }

  // ... (Fungsi _showNotificationDialog dan _logout tidak berubah)
  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
  }

  // ✅ FUNGSI UTAMA UNTUK FILTER DAN SORTIR
  void _filterAndSortBarang() {
    List<dynamic> tempBarang = List.from(_allBarang);

    // 1. Filter berdasarkan teks pencarian
    if (_searchController.text.isNotEmpty) {
      String query = _searchController.text.toLowerCase();
      tempBarang = tempBarang.where((barang) {
        String namaBarang = barang['nama_barang'].toString().toLowerCase();
        return namaBarang.contains(query);
      }).toList();
    }

    // 2. Filter berdasarkan kategori
    if (_selectedKategoriId != null) {
      tempBarang = tempBarang.where((barang) {
        return barang['id_kategori'] == _selectedKategoriId;
      }).toList();
    }

    // 3. Proses Sortir
    switch (_currentSortOption) {
      case SortOption.priceAsc:
        tempBarang.sort((a, b) => a['harga_barang'].compareTo(b['harga_barang']));
        break;
      case SortOption.priceDesc:
        tempBarang.sort((a, b) => b['harga_barang'].compareTo(a['harga_barang']));
        break;
      case SortOption.none:
        // Tidak melakukan apa-apa, urutan default dari server
        break;
    }

    setState(() {
      _filteredBarang = tempBarang;
    });
  }
  
  Future<void> loadHomeData() async {
    try {
      final kategoriRes = await HomeService.fetchKategori();
      final barangRes = await HomeService.fetchBarang();
      setState(() {
        kategori = kategoriRes;
        _allBarang = barangRes; // Simpan data asli
        _filteredBarang = barangRes; // Tampilkan semua data pada awalnya
      });
    } catch (e) {
      print('Error loading home data: $e');
      // Handle error, maybe show a snackbar
    }
  }

  @override
  void initState() {
    super.initState();
    _initApp();
    // Inisialisasi _pages di initState
    _pages = [
      _buildBeranda(),
      const ListMerchandise(), // Ganti dengan ListMerchandise
    ];
  }
  
  @override
  void dispose() {
    _searchController.dispose(); // Jangan lupa dispose controller
    super.dispose();
  }


 @override
  Widget build(BuildContext context) {
    // Inisialisasi _pages di dalam build() agar _buildBeranda() bisa diakses
    final List<Widget> pages = [
      _buildBeranda(),
      const ListMerchandise(), // Perhatikan, ini adalah Widget, bukan navigasi
      const RiwayatTransaksiPembelian(),
      const ProfilePembeli(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: (_selectedIndex == 2 || _selectedIndex == 3) ? null : _buildAppBar(),
      body: pages[_selectedIndex], // Gunakan 'pages' bukan '_pages'
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF005E34),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Handle navigasi untuk Merchandise di sini jika diperlukan
            // if (index == 1) { // Jika Merchandise adalah index 1
            //   Navigator.push(context, MaterialPageRoute(builder: (_) => const ListMerchandise()));
            // }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Merchandise'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF005E34),
      title: _selectedIndex == 1 // Jika indeks adalah 1 (Merchandise)
          ? const Text(
              'Merchandise',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            )
          : _buildSearchBar(), // Jika bukan, tampilkan search bar
      actions: [
        // ... (Tombol notifikasi dan top seller tidak berubah)
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined, color: Colors.white),
          tooltip: 'Top Seller',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TopSellerView()),
            );
          },
        ),
      ],
    );
  }

  // ✅ SEARCH BAR YANG SUDAH BERFUNGSI
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController, // Hubungkan controller
              decoration: const InputDecoration(
                hintText: 'Cari nama barang...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          // Tombol clear untuk menghapus teks
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    return RefreshIndicator(
      onRefresh: loadHomeData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ... (Carousel tidak berubah)
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
          
          // ✅ WIDGET BARU UNTUK TOMBOL SORTIR
          _buildSortButtons(),
          const SizedBox(height: 10),

          const Text('Rekomendasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildBarangGrid(),
        ],
      ),
    );
  }
  
  // ✅ WIDGET BARU: TOMBOL UNTUK SORTIR HARGA
  Widget _buildSortButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_upward),
          label: const Text("Harga Terendah"),
          onPressed: () {
            setState(() {
              _currentSortOption = SortOption.priceAsc;
            });
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
            setState(() {
              _currentSortOption = SortOption.priceDesc;
            });
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
  }

  Widget _carouselItem(String imagePath) {
    // ... (Tidak berubah)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover, // fills the space without distortion
        width: double.infinity,
      ),
    );
  }

  // ✅ KATEGORI YANG BISA DIKLIK
  Widget _buildKategoriList() {
    return SizedBox(
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
              setState(() {
                // Jika kategori yang sama diklik lagi, batalkan filter
                if (isSelected) {
                  _selectedKategoriId = null;
                } else {
                  _selectedKategoriId = item['id_kategori'];
                }
              });
              _filterAndSortBarang(); // Panggil fungsi filter
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF005E34) : const Color(0xFFE1DDD2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.green.shade700,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['kategori'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black, // Ubah warna teks
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ GRID BARANG YANG MENAMPILKAN DATA HASIL FILTER
  Widget _buildBarangGrid() {
    if (_filteredBarang.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Barang tidak ditemukan.\nCoba kata kunci atau filter lain.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredBarang.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7, // Sesuaikan rasio aspek agar lebih pas
      ),
      itemBuilder: (context, index) {
        final item = _filteredBarang[index];
        // Logika untuk mendapatkan URL gambar, dengan fallback jika tidak ada
        final imageUrl = (item['images'] != null && (item['images'] as List).isNotEmpty)
            ? 'https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(item['images'][0]['directory'])}'
            : 'https://via.placeholder.com/160?text=No+Image';

        // ✅ BUNGKUS DENGAN GESTUREDETECTOR
        return GestureDetector(
          onTap: () {
            // Navigasi ke halaman detail saat item ditekan
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailBarangView(barang: item),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menggunakan Expanded agar gambar memenuhi ruang yang tersedia
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_barang'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2, // Batasi nama barang jadi 2 baris
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(item['harga_barang']),
                        style: const TextStyle(
                          color: Color(0xFF005E34),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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