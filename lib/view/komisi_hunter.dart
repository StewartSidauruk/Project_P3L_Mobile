import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/view/login.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class KomisiHunter extends StatefulWidget {
  const KomisiHunter({super.key});

  @override
  State<KomisiHunter> createState() => _KomisiHunter();
}

class _KomisiHunter extends State<KomisiHunter> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? user;
  List<dynamic> _komisiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
    _loadData();
  }

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

  Future<void> _loadData() async {
    await fetchProfile();
    if (user != null) {
      await fetchKomisiHunter(); // tanpa parameter
    }
  }

  Future<void> fetchProfile() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['role'] == 'Pegawai' && data['user']['jabatan']['role'] == 'Hunter') {
        setState(() {
          user = data['user'];
        });
      }
    }
  }

  Future<void> fetchKomisiHunter() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/transaksi-hunter'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _komisiList = data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
      importance: Importance.high,
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

  Widget _buildHistoriKomisiHunter() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_komisiList.isEmpty) {
      return const Center(child: Text("Belum ada komisi untuk Anda."));
    }

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
                Text("Komisi Pegawai: Rp${item['komisi_pegawai']}"),
                Text("Komisi Penitip: Rp${item['komisi_penitip']}"),
                Text("Komisi Reusemart: Rp${item['komisi_reusemart']}"),
                Text("ID Barang: ${item['id_barang']}"),
                Text("ID Pegawai: ${item['id_pegawai']}"),
                Text("ID Penitip: ${item['id_penitip']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildHistoriKomisiHunter(),
    );
  }
}
