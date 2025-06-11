import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'login.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_p3l/view/profile_hunter.dart';
import 'package:flutter_application_p3l/view/komisi_hunter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomeHunter extends StatefulWidget {
  const HomeHunter({super.key});

  @override
  State<HomeHunter> createState() => _HomeHunterState();
}

class _HomeHunterState extends State<HomeHunter> {
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
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void initState() {
    super.initState();
    _initApp(); // panggil setup
  }

  Future<void> _initApp() async {
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
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  final List<Widget> _pages = [
    const Center(child: Text("Home Hunter", style: TextStyle(fontSize: 24))),
    KomisiHunter(),
    const ProfileHunter(),
  ];

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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Komisi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    String titleText;

    if (_selectedIndex == 0) {
      titleText = "Home Hunter";
    } else if (_selectedIndex == 1) {
      titleText = "Komisi";
    } else {
      titleText = "Profil";
    }

    return AppBar(
      backgroundColor: const Color(0xFF005E34),
      title: Text(titleText, style: const TextStyle(color: Colors.white)),
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
}
