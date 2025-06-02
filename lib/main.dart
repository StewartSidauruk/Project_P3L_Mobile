import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'view/login.dart';
import 'view/home_pembeli.dart';
import 'view/home_penitip.dart';
import 'view/home_hunter.dart';
import 'view/home_kurir.dart';

final storage = FlutterSecureStorage();

void main() {
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
