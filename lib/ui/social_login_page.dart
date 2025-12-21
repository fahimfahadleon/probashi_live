import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/auth_service.dart';
import '../utils/utils.dart';
import 'home_page.dart';

class SocialLoginPage extends StatelessWidget {
  const SocialLoginPage({super.key});



  @override
  Widget build(BuildContext context) {

    final GoogleSignIn googleSignIn = GoogleSignIn.instance;


    Future<String?> signInAndGetIdToken() async {
      try {
        final account = await googleSignIn.authenticate();
        final idToken = account.authentication.idToken;
        return idToken; // Send this to your NestJS backend
      } catch (e) {
        print('Google Sign-In error: $e');
        return null;
      }
    }

    Future<void> handleGoogleLogin() async {
      final idToken = await signInAndGetIdToken();
      if (idToken != null) {
        print("idToken: $idToken");
        final response = await AuthService().login(
          provider: AuthProvider.google,
          token: idToken,
        );

        if (response != null) {
          // ✅ Login successful — navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          Utils.showSnackbar(context, "Login Failed!");

        }
      } else {
        print("Token null");
        Utils.showSnackbar(context, "Google Sign-In failed");
      }
    }

    return Scaffold(
      backgroundColor: Colors.white, // Dark background for contrast
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // White text
                ),
              ),
              const SizedBox(height: 40),

              // Google Login Button
              SocialLoginButton(
                icon: FontAwesomeIcons.google,
                text: 'Login with Google',
                color: Colors.red,
                onPressed: () {
                  handleGoogleLogin();
                },
              ),
              const SizedBox(height: 16),

              // Facebook Login Button
              SocialLoginButton(
                icon: FontAwesomeIcons.facebookF,
                text: 'Login with Facebook',
                color: Colors.blue[900]!,
                onPressed: () {
                  // TODO: Implement Facebook Sign-In
                },
              ),
              const SizedBox(height: 16),

              // WhatsApp Login Button
              SocialLoginButton(
                icon: FontAwesomeIcons.whatsapp,
                text: 'Login with WhatsApp',
                color: Colors.green,
                onPressed: () {
                  // TODO: Implement WhatsApp Login
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white), // White label text
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}
