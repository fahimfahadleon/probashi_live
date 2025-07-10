import 'dart:async';

import 'package:flutter/material.dart';
import 'package:probashi_live/ui/top_up_view.dart';
import 'package:probashi_live/utils/api_service.dart';

import '../models/offer.dart';
import '../models/user_profile.dart';
import 'offer_details_view.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _MyPageState();
}

class _MyPageState extends State<ProfileTabView> {
  late Future<UserProfile> _futureProfile;
  UserStats _status = UserStats(followers: 0, following: 0, friends: 0);
  List<Offer> _offers = [];
  int _currentOfferIndex = 0;
  Offer? _currentOffer;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
    fetchMyStats();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      _offers = await ApiService.getApiClient().getOffers();
      if (_offers.isNotEmpty) {
        setState(() {
          _currentOffer = _offers[0];
        });

        _offerTimer?.cancel();
        _offerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          setState(() {
            _currentOfferIndex = (_currentOfferIndex + 1) % _offers.length;
            _currentOffer = _offers[_currentOfferIndex];
          });
        });
      }
    } catch (e) {
      print("Error loading offers: $e");
    }
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    super.dispose();
  }

  Future<UserProfile> _loadProfile() async {
    return await ApiService.getApiClient().getMyProfile();
  }

  Future<void> fetchMyStats() async {
    try {
      final stats = await ApiService.getApiClient().getMyStats();
      setState(() {
        _status = stats;
      });
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No profile found"));
          }

          final userProfile = snapshot.data!;

          return _buildProfileBody(userProfile); // keep body clean and separate
        },
      ),
    );
  }

  Widget _buildProfileBody(UserProfile userProfile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        gradient: LinearGradient(
          colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
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
                    SizedBox(height: 40),
                    Center(
                      child: ClipOval(
                        child: SizedBox(
                          width: 100, // radius * 2
                          height: 100,
                          child: Image.network(
                            userProfile.profilePic,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                alignment: Alignment.center,
                                child: const Icon(Icons.person, size: 40,
                                    color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(userProfile.name, style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("ID:${userProfile.id}",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        userProfile.bio?.isEmpty ?? true
                            ? "Hi, I am using Probashi Live"
                            : userProfile.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Badges
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text("Lv ${userProfile.level}")),

                  Container(
                    height: 32,
                    // Match Chip height
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.diamond, color: Colors.blue, size: 18),
                  ),

                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.mic, color: Colors.deepPurple, size: 18),
                  ),

                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        Icons.emoji_events, color: Colors.brown, size: 18),
                  ),

                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        Icons.verified_user, color: Colors.green, size: 18),
                  ),
                ],
              ),


              // Beans and Diamonds Row
              Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        const Icon(Icons.local_fire_department, color: Colors
                            .orange),
                        const SizedBox(height: 4),
                        Text(userProfile.vipStatus ? "VIP" : "Non VIP"),
                      ]),
                      Column(children: [
                        Icon(Icons.favorite, color: Colors.red),
                        SizedBox(height: 4),
                        Text("${userProfile.diamond} Diamonds"),
                      ]),
                    ],
                  ),
                ),
              ),

              // Friends / Followers / Following
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoColumn(title: "Friends", value: _status.friends
                          .toString()
                          .isEmpty ? "0" : _status.friends.toString()),
                      _InfoColumn(title: "Followers", value: _status.followers
                          .toString()
                          .isEmpty ? "0" : _status.followers.toString()),
                      _InfoColumn(title: "Following", value: _status.following
                          .toString()
                          .isEmpty ? "0" : _status.following.toString()),
                    ],
                  ),
                ),
              ),

              if (_currentOffer != null)
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentOffer!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentOffer!.content,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfferDetailsView(offer: _currentOffer!),
                            ),
                          );
                        },
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
                  children: [
                    _GridIcon(icon: Icons.monetization_on,
                      label: "Top-up",
                      onTap: () =>
                      {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TopUpView())
                        ),
                      },
                    ),
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
        Text(
            value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}


class _GridIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GridIcon({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // invoke callback when tapped
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.deepPurple),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
