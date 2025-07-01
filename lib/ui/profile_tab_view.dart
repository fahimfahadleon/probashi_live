import 'package:flutter/material.dart';

class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)], // light purple to sky
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                // Profile Avatar + Info
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/profile.jpg'), // use NetworkImage() for real
                      ),
                      const SizedBox(height: 10),
                      Text("SUPER IS BACK💕", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("ID:574499730 | Bangladesh", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "আমি আমার মতো থাকতে চাই আর তুমি তোমার মতো থাকো আমাকে আর ডিস্টার্ব কইরো না 🙏🙏",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Badges
                Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text("Lv1")),
                    Icon(Icons.diamond, color: Colors.blue),
                    Icon(Icons.mic, color: Colors.deepPurple),
                    Icon(Icons.emoji_events, color: Colors.brown),
                    Icon(Icons.verified_user, color: Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                // Beans and Diamonds Row
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(children: [
                          Icon(Icons.local_fire_department, color: Colors.orange),
                          SizedBox(height: 4),
                          Text("54 Beans"),
                        ]),
                        Column(children: [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(height: 4),
                          Text("828 Diamonds"),
                        ]),
                      ],
                    ),
                  ),
                ),

                // Friends / Followers / Following
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _InfoColumn(title: "Friends", value: "46"),
                        _InfoColumn(title: "Followers", value: "120"),
                        _InfoColumn(title: "Following", value: "139"),
                      ],
                    ),
                  ),
                ),

                // VVIP Banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.indigo],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("CLAIM 🥭 5,401 EVERYDAY!", style: TextStyle(color: Colors.white)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {},
                        child: const Text("Activate"),
                      ),
                    ],
                  ),
                ),

                // Icon Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _GridIcon(icon: Icons.monetization_on, label: "Top-up"),
                      _GridIcon(icon: Icons.wallet, label: "Earnings"),
                      _GridIcon(icon: Icons.task, label: "My Tasks"),
                      _GridIcon(icon: Icons.star, label: "VIP"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String value;

  const _InfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GridIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
