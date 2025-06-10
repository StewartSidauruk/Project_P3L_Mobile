import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'login.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class KomisiHunter extends StatefulWidget {
  const KomisiHunter({super.key});

  @override
  State<KomisiHunter> createState() => _KomisiHunter();
}

class _KomisiHunter extends State<KomisiHunter> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? user;
  List<String> _notifications = [];
  List<dynamic> _komisiList = []; // Pindahkan deklarasi ke sini

  Future<void> _refreshNotifications() async {
    final data = await NotifikasiService.fetchNotifikasi();
    setState(() {
      _notifications = data;
    });
  }

  Future<void> fetchProfile() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      print("Token tidak ditemukan.");
      return;
    }
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Data Profil Pengguna: $data");
      if (data['role'] == 'Pegawai' && data['user']['jabatan']['role'] == 'Hunter') {
        setState(() {
          user = data['user'];
        });
        print("User berhasil diidentifikasi sebagai Hunter.");
      } else {
        print("User bukan Hunter: Role: ${data['role']}, Jabatan: ${data['user']['jabatan']['role']}");
      }
    } else {
      print("Gagal mengambil data hunter: Status: ${response.statusCode}, Body: ${response.body}");
    }
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

  @override
  void initState() {
    super.initState();
    _initApp();
    fetchProfile();
    fetchKomisiHunter();
  }

  Future<void> _initApp() async {
    await initLocalNotifications();

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
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
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> fetchKomisiHunter() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      print("Token tidak ditemukan saat fetchKomisiHunter.");
      return;
    }
    print("Token ditemukan: $token"); // Debug token
    final url = Uri.parse('http://10.0.2.2:8000/api/transaksiHunter');
    print("Mengambil data dari URL: $url"); // Debug URL

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print("Status code: ${response.statusCode}"); // Debug status code
      print("Response body: ${response.body}"); // Debug response body

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _komisiList = data;
        });
        print("Data Komisi Hunter berhasil diambil. Jumlah item: ${_komisiList.length}");
        print("Isi Komisi List: $_komisiList");
      } else {
        print("Gagal mengambil data komisi: Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Terjadi kesalahan saat fetchKomisiHunter: $e"); // Tangani error jaringan/lainnya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildHistoriKomisiHunter(),
    );
  }

  Widget _buildHistoriKomisiHunter() {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter komisiList berdasarkan id_pegawai yang sedang login jika perlu
    // Namun, dengan perubahan di controller Laravel, ini seharusnya tidak lagi diperlukan
    // karena controller sudah memfilter data berdasarkan id_pegawai yang login.
    // Tetapi jika ingin menambahkan filtering di client-side sebagai redundansi, bisa seperti ini:
    // final filteredKomisiList = _komisiList.where((item) => item['id_pegawai'] == user!['id_pegawai']).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _komisiList.length, // Gunakan _komisiList langsung
      itemBuilder: (context, index) {
        final item = _komisiList[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaksi Komisi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("ID Komisi: ${item['id_komisi']}", style: const TextStyle(fontSize: 15)), // Menampilkan ID Komisi
                Text("Nama Barang: ${item['nama_barang']}", style: const TextStyle(fontSize: 15)),
                Text("Tanggal Lunas: ${item['tanggal_lunas'] ?? 'Belum lunas'}", style: const TextStyle(fontSize: 14)),
                Text(
                  "Komisi Pegawai: Rp${item['komisi_pegawai']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005E34),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      // Bisa arahkan ke halaman detail jika ada
                    },
                    child: const Text("Lihat Detail"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}