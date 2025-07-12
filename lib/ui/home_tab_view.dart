import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:probashi_live/ui/single_user_card.dart';
import 'package:probashi_live/ui/user_live_page.dart';
import 'package:probashi_live/utils/api_service.dart';

import '../models/announcement_model.dart';
import '../models/user_card_data.dart';
import 'custom_tab_bar.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  Announcement? _latestAnnouncement;
  final List<UserCardData> _allUsers = List.generate(
    50,
        (index) => UserCardData(
      id: index,
      name: "User $index",
      tags: index % 2 == 0 ? ["PK", "Big Star"] : ["FreshersBuzz!"],
      views: 9000 + index * 100,
      isLive: index % 5 == 0,
      imageUrl: "https://i.pravatar.cc/150?img=${index % 70}",
    ),
  );

  static const int pageSize = 15;
  int _currentMaxIndex = pageSize;

  List<UserCardData> get _visibleUsers =>
      _allUsers.take(_currentMaxIndex).toList();

  @override
  void initState() {
    super.initState();
    _fetchAnnouncement();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });

  }


  Future<void> _fetchAnnouncement() async {
    try {
      final announcements = await ApiService.getApiClient().getAllAnnouncements();
      setState(() {
        _latestAnnouncement =  announcements.isNotEmpty ? announcements.first : null;

      });
    } catch (e) {
      print(e);
    }
  }

  void _loadMore() {
    if (_currentMaxIndex >= _allUsers.length) return;
    setState(() {
      _currentMaxIndex = (_currentMaxIndex + pageSize).clamp(
        0,
        _allUsers.length,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.white70),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Search",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.emoji_events, color: Colors.amberAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text("😊", style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 6),
          child: CustomTabBar(
            selectedIndex: _tabController.index,
            tabs: ["Freshers", "Popular", "Spotlight", "Party", "PK Matches"],
            onTap: (index) {
              setState(() {
                _tabController.index = index;
              });
            },
          ),
        ),

        if (_latestAnnouncement != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.shade200.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestAnnouncement!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _latestAnnouncement!.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),


        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                "🌍 Global",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MasonryGridView.count(
                  controller: _scrollController,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: _visibleUsers.length,
                  itemBuilder: (context, i) {
                    final user = _visibleUsers[i];
                    return UserCard(
                      data: user,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserLivePage(user: user),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}