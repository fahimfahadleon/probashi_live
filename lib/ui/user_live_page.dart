import 'package:flutter/material.dart';
import '../models/user_card_data.dart';

class UserLivePage extends StatelessWidget {
  final UserCardData user;
  const UserLivePage({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Center(
        child: Text(
          "Details for ${user.name}",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}