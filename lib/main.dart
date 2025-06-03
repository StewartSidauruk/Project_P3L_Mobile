import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'view/login.dart';
import 'view/home_pembeli.dart';
import 'view/home_penitip.dart';
import 'view/home_hunter.dart';
import 'view/home_kurir.dart';

// ✅ Wajib: Handler background (ditempatkan DI ATAS main)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 [Background] Message received: ${message.notification?.title} - ${message.notification?.body}");
}

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Daftarkan background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Update token otomatis saat token FCM berubah
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final authToken = await storage.read(key: 'token');
    if (authToken != null) {
      await http.post(
        Uri.parse('http://10.0.2.2:8000/api/simpan-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: {'expo_push_token': newToken},
      );
      print("🔁 Token FCM diperbarui otomatis ke backend: $newToken");
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    return const LoginView();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data!,
        );
      },
    );
  }
}