import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:probashi_live/ui/home_page.dart';
import 'package:probashi_live/ui/social_login_page.dart';
import 'package:probashi_live/utils/utils.dart';

void main() {
  initGoogleSignIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

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
          return isLoggedIn
              ? const DoubleBackToExit(child: HomePage())
              : const SocialLoginPage();
        },
      ),
    );
  }
}

/// ✅ Updated for Flutter 3.12+: Uses PopScope instead of WillPopScope
class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  const DoubleBackToExit({super.key, required this.child});

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevents automatic popping
      onPopInvokedWithResult: (didPop, result) {
        // If already popped, ignore
        if (didPop) return;

        final now = DateTime.now();
        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          Utils.showToast(context,'Press back again to exit');
          return;
        }

        // Exit app manually
        Navigator.of(context).maybePop();
      },
      child: widget.child,
    );
  }
}
Future<void> initGoogleSignIn() async {
  await GoogleSignIn.instance.initialize(
    clientId: '760404179157-q70boclprl7dm94htpka652cnl612ssq.apps.googleusercontent.com',
    serverClientId: '760404179157-n7akn310nvm9h100he7kikkj09d2ad72.apps.googleusercontent.com',
  );
}




