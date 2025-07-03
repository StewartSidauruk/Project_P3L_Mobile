import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_p3l/services/merchandise_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final storage = FlutterSecureStorage();
 Map<String, dynamic>? user;


class ListMerchandise extends StatefulWidget {
  const ListMerchandise({super.key});

  @override
  State<ListMerchandise> createState() => _ListMerchandise();
}

class _ListMerchandise extends State<ListMerchandise> {
  int _selectedIndex = 0;
  List<String> _notifications = [];

  Future<void> _loadUser() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('https://projectp3l-production.up.railway.app/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['role'] == 'Pembeli') {
        setState(() {
          user = data['user'];
        });
      }
    } else {
      print("Gagal mengambil data pembeli: ${response.body}");
    }
  }


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

  List<dynamic> _merchandiseList = [];

  @override
  void initState() {
    super.initState();
    _initApp();
    _loadMerchandise();
    _loadUser();
  }

  void _showMerchandiseModal(Map<String, dynamic> item) {
    final nama = item['nama_merchandise'];
    final poinMerchandise = item['poin_merchandise'];
    final foto = item['foto_merchandise'];
    final idMerchandise = item['id_merchandise'];
    final stokMerchandise = item['stock_merchandise'];
    final poinPembeli = user?['poin_pembeli'] ?? 0;
    int jumlahKlaim = 1; // Default jumlah klaim

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final int totalPoinDiperlukan = poinMerchandise * jumlahKlaim;
            final bool isPoinCukup = poinPembeli >= totalPoinDiperlukan;
            final bool isStokCukup = stokMerchandise >= jumlahKlaim;

            return AlertDialog(
              title: Text(nama),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(foto),
                  const SizedBox(height: 10),
                  Text('Poin Merchandise: $poinMerchandise'),
                  Text('Stok Tersedia: $stokMerchandise'),
                  Text('Poin Anda: $poinPembeli'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (jumlahKlaim > 1) {
                            setState(() {
                              jumlahKlaim--;
                            });
                          }
                        },
                      ),
                      Text('$jumlahKlaim'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (jumlahKlaim < stokMerchandise) { // Batasi klaim sesuai stok
                            setState(() {
                              jumlahKlaim++;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Poin yang Dibutuhkan: $totalPoinDiperlukan',
                    style: TextStyle(
                      color: isPoinCukup ? Colors.black : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isPoinCukup && isStokCukup)
                    ElevatedButton(
                      onPressed: () => _tukarPoin(idMerchandise, jumlahKlaim),
                      child: const Text('Tukar Poin'),
                    )
                  else if (!isPoinCukup)
                    const Text(
                      'Poin Anda Belum Cukup untuk ditukarkan',
                      style: TextStyle(color: Colors.red),
                    )
                  else if (!isStokCukup)
                    const Text(
                      'Stok merchandise tidak cukup',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _tukarPoin(int idMerchandise, int jumlahKlaim) async {
    final idPembeli = user?['id_pembeli'];

    try {
      final response = await MerchandiseService.tukarPoin(idPembeli, idMerchandise, jumlahKlaim);

      if (response['message'] == 'Penukaran berhasil') {
        Navigator.pop(context); // Tutup modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PENUKARAN BERHASIL DILAKUKAN')),
        );
        _loadMerchandise();
        _loadUser();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadMerchandise() async {
    try {
      final data = await MerchandiseService.fetchMerchandise();
      setState(() {
        _merchandiseList = data;
      });
    } catch (e) {
      print('Error fetching merchandise: $e');
    }
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildMerchandiseGrid(),
    );
  }


  Widget _buildMerchandiseGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _merchandiseList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              itemCount: _merchandiseList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = _merchandiseList[index];
                final foto = item['foto_merchandise'] as String? ?? '';
                final nama = item['nama_merchandise'] as String? ?? 'Tanpa Nama';
                final poin = item['poin_merchandise'] ?? 0;
                final stok = item['stock_merchandise'] ?? 0;

                return InkWell(
                  onTap: () => _showMerchandiseModal(item),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '$poin points',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              Text('$stok pcs', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}