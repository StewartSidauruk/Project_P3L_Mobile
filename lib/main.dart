import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// Import yang diperlukan untuk memperbaiki error locale
import 'package:intl/date_symbol_data_local.dart';

import 'view/login.dart';
import 'view/home_pembeli.dart';
import 'view/home_penitip.dart';
import 'view/home_hunter.dart';
import 'view/home_kurir.dart';
import 'view/umum_view.dart';

final storage = FlutterSecureStorage();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handler notifikasi background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📥 [BG] Notifikasi masuk: ${message.toMap()}');

  String? title = message.notification?.title ?? message.data['title'];
  String? body = message.notification?.body ?? message.data['body'];

  print('💡 [BG Handler] Title: $title, Body: $body');

  if (title != null && body != null) {
    print('📣 [BG Handler] Memanggil flutterLocalNotificationsPlugin.show');
    try {
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
      print(
          '✅ [BG Handler] flutterLocalNotificationsPlugin.show BERHASIL dipanggil');
    } catch (e) {
      print('❌ [BG Handler] Error saat memanggil show: $e');
    }
  } else {
    print(
        '⚠️ [BG Handler] Title atau Body kosong, tidak menampilkan notifikasi lokal.');
  }
}

/// Setup notifikasi channel Android
Future<void> setupFlutterNotifications() async {
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

Future<void> simpanTokenFcmKeBackend() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  final jwt = await storage.read(key: 'token');

  if (fcmToken != null && jwt != null) {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/simpan-token'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    if (response.statusCode == 200) {
      print("✅ FCM token berhasil dikirim ulang");
    } else {
      print("❌ Gagal kirim FCM token: ${response.body}");
    }
  }
}

/// Minta izin notifikasi (Android 13+)
Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data locale untuk format 'id_ID'
  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp();

  await requestNotificationPermission();
  await setupFlutterNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Kirim token FCM ke Laravel
  final fcmToken = await FirebaseMessaging.instance.getToken();
  final token = await storage.read(key: 'token');
  if (fcmToken != null && token != null) {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/simpan-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {'fcm_token': fcmToken},
    );
    if (response.statusCode == 200) {
      print("✅ Token FCM berhasil disimpan.");
    } else {
      print("❌ Gagal menyimpan token FCM: ${response.body}");
    }
  }

  FirebaseMessaging.instance.getToken().then((token) {
    print("✅ FCM Token: $token");
  });

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<Widget> _getInitialPage() async {
    final token = await storage.read(key: 'token');
    final role = await storage.read(key: 'role');

    if (token != null && role != null) {
      switch (role) {
        case 'Pembeli':
          return const HomePembeli();
        case 'Penitip':
          return const HomePenitip();
        case 'Hunter':
          return const HomeHunter();
        case 'Kurir':
          return const HomeKurir();
      }
    }

    // MODIFIKASI: Ganti LoginView() menjadi UmumView()
    return const UmumView();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data!,
        );
      },
    );
  }
}