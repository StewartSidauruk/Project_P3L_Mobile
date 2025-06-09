import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class ListMerchandise extends StatefulWidget {
  const ListMerchandise({super.key});

  @override
  State<ListMerchandise> createState() => _ListMerchandise();
}

class _ListMerchandise extends State<ListMerchandise> {
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
      appBar: _buildAppBar(),
      body: _buildMerchandiseGrid(),
    );
  }

  AppBar _buildAppBar() {
  return AppBar(
    backgroundColor: const Color(0xFF005E34),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        Navigator.pop(context); // Navigasi ke halaman sebelumnya
      },
    ),
    title: const Text(
      'Merchandise',
      style: TextStyle(color: Colors.white),
    ),
    actions: [
      
    ],
  );
}

  Widget _buildMerchandiseGrid() {
    final List<Map<String, dynamic>> merchandise = List.generate(6, (index) => {
          'image': 'assets/images/tas_jaman_mataram.png',
          'name': 'Tas jaman mataram',
          'points': 3000,
          'qty': 1,
        });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: merchandise.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final item = merchandise[index];
          return Container(
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
                    child: Image.asset(
                      item['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${item['points']} points',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Text('${item['qty']} pcs', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}