import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:probashi_live/ui/home_page.dart';
import 'package:probashi_live/ui/social_login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    // TODO: optionally verify token with API before trusting it

    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Login',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: FutureBuilder<bool>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isLoggedIn = snapshot.data!;
          return isLoggedIn ? const HomePage() : const SocialLoginPage();
        },
      ),
    );
  }
}
Future<void> initGoogleSignIn() async {
  await GoogleSignIn.instance.initialize(
    clientId: '760404179157-q70boclprl7dm94htpka652cnl612ssq.apps.googleusercontent.com', // For native sign-in
    serverClientId: '760404179157-n7akn310nvm9h100he7kikkj09d2ad72.apps.googleusercontent.com', // For ID token (backend)
  );
}




