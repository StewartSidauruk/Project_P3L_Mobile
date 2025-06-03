import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahkan ini
import 'package:flutter_application_p3l/view/home.dart';
import 'package:flutter_application_p3l/view/register.dart';
import 'package:flutter_application_p3l/auth/auth.dart';
import 'package:flutter_application_p3l/view/home_pembeli.dart';
import 'package:flutter_application_p3l/view/home_penitip.dart';
import 'package:flutter_application_p3l/view/home_hunter.dart';
import 'package:flutter_application_p3l/view/home_kurir.dart';
import 'package:flutter_application_p3l/services/notifikasi_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113C23),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'images/logo.png',
                    height: 160,
                    width: 160,
                  ),
                  // const Padding(
                  //   padding: EdgeInsets.only(bottom: 20),
                  //   child: Text(
                  //     'REUSEMART',
                  //     style: TextStyle(
                  //       fontSize: 26,
                  //       fontWeight: FontWeight.bold,
                  //       color: Color.fromARGB(255, 211, 103, 31),
                  //     ),
                  //   ),
                  // ),
                  inputForm(
                    (p0) => (p0 == null || p0.isEmpty)
                        ? "Email tidak boleh kosong"
                        : null,
                    controller: emailController,
                    hintTxt: "Email",
                    helperTxt: "Inputkan Email Anda",
                    iconData: Icons.email,
                  ),
                  inputForm(
                    (p0) => (p0 == null || p0.isEmpty)
                        ? "Sandi tidak boleh kosong"
                        : null,
                    password: true,
                    controller: passwordController,
                    hintTxt: "Password",
                    helperTxt: "Inputkan Password Anda",
                    iconData: Icons.password,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final response = await AuthService.login(
                          email: emailController.text,
                          password: passwordController.text,
                          role: selectedValue,
                        );

                        if (response['status'] == 'success' && mounted) {
                          final role = response['role'];

                          if (role == 'pembeli') {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePembeli()));
                          } else if (role == 'penitip') {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePenitip()));
                          } else if (role == 'hunter') {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeHunter()));
                          } else if (role == 'kurir') {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeKurir()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Role tidak dikenal")),
                            );
                          }
                        } else {
                          // 🔔 Menampilkan notifikasi error jika login gagal
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['message'] ?? 'Login gagal'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 70, 162, 65),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 135),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  Widget inputForm(
    String? Function(String?) validator, {
    required TextEditingController controller,
    required String hintTxt,
    required String helperTxt,
    required IconData iconData,
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: password,
        validator: validator,
        style: const TextStyle(color: Color(0xFF113C23)),
        decoration: InputDecoration(
          hintText: hintTxt,
          hintStyle: const TextStyle(color: Color(0xFF113C23)),
          helperText: helperTxt,
          helperStyle:
              const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          prefixIcon: Icon(iconData, color: Color(0xFF113C23)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget socialButton(IconData icon, String url) {
    return ElevatedButton.icon(
      onPressed: () => _launchURL(url),
      icon: FaIcon(icon, size: 24),
      label: const Text(''),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void pushRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> saveFcmToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  final storage = FlutterSecureStorage();
  final authToken = await storage.read(key: 'token');

  if (authToken != null && fcmToken != null) {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/simpan-token'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
      body: {'expo_push_token': fcmToken},
    );

    print("📡 Kirim token status: ${response.statusCode}");
    print("📡 Body: ${response.body}");
  } else {
    print("❌ Token atau auth belum tersedia.");
  }
}

}
