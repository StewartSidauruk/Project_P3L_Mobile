import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class ProfileHunter extends StatefulWidget {
  const ProfileHunter({super.key});

  @override
  State<ProfileHunter> createState() => _ProfileHunter();
}

class _ProfileHunter extends State<ProfileHunter> {
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
      body: _buildProfileContent(),
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
      'Profile',
      style: TextStyle(color: Colors.white),
    ),
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
                      children: _notifications
                          .map((notif) => ListTile(
                                leading: const Icon(Icons.notifications),
                                title: Text(notif),
                              ))
                          .toList(),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Foto Profil
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/fox_avatar.png'),
            ),
            const SizedBox(height: 30),

            // Nama
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F6EF),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Text(
                'Nama : Penitip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // Email
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Text(
                'Email : penitip@gmail.com',
                style: TextStyle(fontSize: 16),
              ),
            ),

            // Nomor HP
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Text(
                'No HP : 081212341234',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            // Komisi Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: const [
                    Text(
                      'Jumlah Komisi 🐝',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Rp 200.000',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005E34),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Ayo tingkatkan lagi ngulimu'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

}