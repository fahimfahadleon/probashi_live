import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:probashi_live/ui/audience_page.dart';
import 'package:probashi_live/ui/cached_network_box_image.dart';
import 'package:probashi_live/utils/api_service.dart';
import 'package:probashi_live/utils/socket_service.dart'; // Import your socket service
import 'package:probashi_live/utils/utils.dart';

import '../models/announcement_model.dart';
import '../models/live_session.dart';

import '../utils/variables.dart';
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

  // Live sessions from socket
  List<LiveSession> _liveSessions = [];
  bool _loadingLiveSessions = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncement();

    _tabController = TabController(length: 5, vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Optional: implement pagination for live sessions if your backend supports it
      }
    });

    _setupSocket();
  }

  Future<void> _fetchAnnouncement() async {
    try {
      final announcements = await ApiService.getApiClient()
          .getAllAnnouncements();
      setState(() {
        _latestAnnouncement = announcements.isNotEmpty
            ? announcements.first
            : null;
      });
    } catch (e) {
      print(e);
    }
  }

  void _setupSocket() {
    SocketService.instance.onActiveLiveSessions((sessions) {
      setState(() {
        _liveSessions = sessions;
        _loadingLiveSessions = false;
      });
    });
    SocketService.instance.requestActiveLiveSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    SocketService.instance.disconnect();
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: CustomTabBar(
            selectedIndex: _tabController.index,
            tabs: ["Lives", "Games"],
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                onPressed: () {
                  // Optional: Add filter action
                },
                icon: const Icon(Icons.filter_alt, color: Colors.white70),
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(5, (index) {
              return RefreshIndicator(
                color: Colors.white,
                backgroundColor: Colors.pinkAccent,
                onRefresh: () async {
                  setState(() {
                    _loadingLiveSessions = true;
                  });
                  SocketService.instance.requestActiveLiveSessions();
                },
                child: _loadingLiveSessions
                    ? const Center(child: CircularProgressIndicator())
                    : _liveSessions.isEmpty
                    ? ListView(
                        // ListView is needed for RefreshIndicator to work when empty
                        children: [
                          SizedBox(height: 200),
                          Center(
                            child: Text(
                              "No live sessions found",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: MasonryGridView.count(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          itemCount: _liveSessions.length,
                          itemBuilder: (context, i) {
                            final liveSession = _liveSessions[i];
                            final hostUser = liveSession.hosts.isNotEmpty
                                ? liveSession.hosts.first.user
                                : null;

                            return GestureDetector(
                              onTap: () {
                                if (hostUser != null) {
                                  String url =
                                      "${Variables.RTMP_URL}/${liveSession.hosts.first.user.id}";
                                  print(url);

                                  Utils.printGreenComment(liveSession.toJson().toString());
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AudiencePage(
                                        liveSession: liveSession,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                      hostUser?.profilePic != null
                                          ? CachedNetworkImageBox(imageUrl: hostUser!.profilePic,height: 120,)
                                          : Container(
                                              height: 120,
                                              color: Colors.grey,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 50,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      hostUser?.name ?? "Unknown Host",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Live Now",
                                      style: TextStyle(
                                        color: Colors.redAccent.shade200,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
