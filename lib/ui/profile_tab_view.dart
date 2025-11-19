import 'dart:async';

import 'package:flutter/material.dart';
import 'package:probashi_live/ui/cached_circle_avatar.dart';
import 'package:probashi_live/ui/coin_seller.dart';
import 'package:probashi_live/ui/social_relation_page.dart';
import 'package:probashi_live/ui/top_up_view.dart';
import 'package:probashi_live/ui/vip_controllers.dart';
import 'package:probashi_live/utils/api_service.dart';

import '../models/offer.dart';
import '../models/user_profile.dart';
import '../utils/variables.dart';
import 'my_collections.dart';
import 'offer_details_view.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _MyPageState();
}

class _MyPageState extends State<ProfileTabView> {
  late Future<UserProfile> _futureProfile;
  UserStats _status = UserStats(followers: 0, following: 0, friends: 0);
  List<ProductOfferDto> _offers = [];
  int _currentOfferIndex = 0;
  ProductOfferDto? _currentOffer;
  Timer? _offerTimer;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
    _futureProfile.then((profile) async {
      await fetchUserStats(profile.id);
      fetchOffers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh profile each time this tab becomes visible again
    if (!_hasLoaded) {
      _hasLoaded = true; // prevent double call on initial mount
    } else {
      _futureProfile = _initData(); // refresh user data
      setState(() {}); // triggers rebuild
    }
  }

  Future<UserProfile> _initData() async {
    final profile = await _loadProfile();
    await fetchUserStats(profile.id); // updates stats
    fetchOffers(); // fetch latest offers
    return profile;
  }

  Future<UserProfile> _loadProfile() async {
    UserProfile profile = await ApiService.getApiClient().getMyProfile();
    Variables.currentUser = profile;
    return profile;
  }

  Future<void> fetchUserStats(String userId) async {
    try {
      final stats = await ApiService.getApiClient().getUserStats(userId);
      Variables.currentUser?.stats = stats;
      setState(() {
        _status = stats;
      });
    } catch (e) {
      print('Error fetching stats: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _futureProfile = _initData();
          setState(() {});
        },
        child: FutureBuilder<UserProfile>(
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

            return _buildProfileBody(
              userProfile,
            ); // keep body clean and separate
          },
        ),
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
                        child: CachedCircleAvatar(
                      imageUrl: userProfile.profilePic,
                      user: userProfile.settings,
                      radius: 50,)
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userProfile.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID:${userProfile.id}",
                      style: TextStyle(color: Colors.grey),
                    ),
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
                      Icons.emoji_events,
                      color: Colors.brown,
                      size: 18,
                    ),
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
                      Icons.verified_user,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                ],
              ),

              // Beans and Diamonds Row
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 4),
                          Text(userProfile.vipStatus ? "VIP" : "Non VIP"),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(height: 4),
                          Text("${userProfile.diamond} Diamonds"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Friends / Followers / Following
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InfoColumn(
                        title: "Friends",
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SocialRelationsPage(initialTab: 1), // opens Followers
                            ),
                          );

                        },
                        value: _status.friends.toString().isEmpty
                            ? "0"
                            : _status.friends.toString(),
                      ),
                      InfoColumn(
                        title: "Followers",
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SocialRelationsPage(initialTab: 2), // opens Followers
                            ),
                          );

                        },
                        value: _status.followers.toString().isEmpty
                            ? "0"
                            : _status.followers.toString(),
                      ),
                      InfoColumn(
                        title: "Following",
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SocialRelationsPage(initialTab: 3), // opens Followers
                            ),
                          );

                        },
                        value: _status.following.toString().isEmpty
                            ? "0"
                            : _status.following.toString(),
                      ),
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
                              _currentOffer!.offer.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentOffer!.offer.content,
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
                              builder: (context) =>
                                  OfferListView(),
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
                    _GridIcon(
                      icon: Icons.monetization_on,
                      label: "Top-up",
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TopUpView(),
                          ),
                        ),
                      },
                    ),
                    _GridIcon(icon: Icons.wallet, label: "Earnings"),
                    _GridIcon(icon: Icons.task, label: "My Tasks"),
                    _GridIcon(icon: Icons.wallet, label: "Diamond Seller",onTap: (){

                    },),
                    _GridIcon(icon: Icons.currency_bitcoin, label: "Diamond Transfer",onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CoinSellerPage(),
                        ),
                      );
                    },),
                    _GridIcon(
                      icon: Icons.collections,
                      label: "Baggage",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyCollections(),
                          ),
                        );
                      },
                    ),
                    _GridIcon(
                      icon: Icons.star,
                      label: "VIP",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VipControllers(),
                          ),
                        );
                      },
                    ),
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

class InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onPressed;

  const InfoColumn({
    super.key,
    required this.title,
    required this.value,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GridIcon({required this.icon, required this.label, this.onTap});

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
