import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Hapus import yang tidak diperlukan lagi
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// Import service yang baru dan halaman Login
import 'package:flutter_application_p3l/services/komisiHunter_service.dart';
import 'package:flutter_application_p3l/view/login.dart'; 

// Inisialisasi plugin notifikasi di level global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class KomisiHunter extends StatefulWidget {
  const KomisiHunter({super.key});

  @override
  State<KomisiHunter> createState() => _KomisiHunterState();
}

class _KomisiHunterState extends State<KomisiHunter> {
  // State variables disederhanakan
  List<dynamic> _komisiList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Memanggil kedua fungsi inisialisasi
    _initApp();
    _loadKomisiData();
  }

  // Navigasi ke halaman Login jika token tidak valid atau role salah
  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (Route<dynamic> route) => false,
      );
    }
  }

  //==================================================================
  // LOGIKA PEMUATAN DATA (MENGGUNAKAN SERVICE)
  //==================================================================
  
  Future<void> _loadKomisiData() async {
    try {
      // 1. Verifikasi profil terlebih dahulu melalui service
      // Jika user bukan Hunter, service akan melempar exception
      await KomisiHunterService.fetchProfileAsHunter();
      
      // 2. Jika lolos, ambil daftar komisi melalui service
      final komisiData = await KomisiHunterService.fetchKomisiHunterList();
      
      if (mounted) {
        setState(() {
          _komisiList = komisiData;
          _isLoading = false;
        });
      }

    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      if (message == '401' || message == 'Bukan Hunter') {
        // Jika token tidak valid atau user bukan hunter, paksa kembali ke login
        _navigateToLogin();
      } else if (message == '403') {
        // Jika akses ditolak secara eksplisit oleh server
         setState(() {
          _errorMessage = 'Anda tidak memiliki izin untuk melihat data ini.';
          _isLoading = false;
        });
      } else {
        // Untuk error lainnya (koneksi, server 500, dll.)
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showKomisiDetail(String idKomisi) async {
    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Panggil detail komisi dari service
      final detailData = await KomisiHunterService.fetchKomisiHunterDetail(idKomisi);
      Navigator.of(context).pop(); // Tutup dialog loading

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Detail Komisi', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID Komisi:', detailData['id_komisi']?.toString() ?? 'N/A'),
                  _buildDetailRow('Nama Barang:', detailData['nama_barang'] ?? 'N/A'),
                  _buildDetailRow('Nama Penitip:', detailData['nama_penitip'] ?? 'N/A'),
                  _buildDetailRow('Tanggal Masuk Barang:', detailData['tanggal_masuk'] ?? 'N/A'),
                  _buildDetailRow('Komisi Pegawai:', 'Rp${detailData['komisi_pegawai']?.toString() ?? '0'}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Tutup dialog loading jika error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  //==================================================================
  // LOGIKA NOTIFIKASI (TETAP SAMA SEPERTI SEBELUMNYA)
  //==================================================================
  
  Future<void> _initApp() async {
    await _requestNotificationPermission();
    await _initLocalNotifications();

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
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifikasi Penting',
      description: 'Channel untuk notifikasi penting',
      importance: Importance.max,
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

  //==================================================================
  // BAGIAN UI (TIDAK ADA PERUBAHAN SIGNIFIKAN)
  //==================================================================
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_komisiList.isEmpty) {
      return const Center(child: Text("Belum ada komisi untuk Anda."));
    }

    // Membangun list jika data berhasil dimuat
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _komisiList.length,
      itemBuilder: (context, index) {
        final item = _komisiList[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Komisi Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("ID Komisi: ${item['id_komisi']}"),
                Text("Nama Barang: ${item['nama_barang'] ?? 'N/A'}"),
                Text("Komisi Pegawai: Rp${item['komisi_pegawai']}"),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () => _showKomisiDetail(item['id_komisi'].toString()),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Lihat Detail'),
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
