import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:probashi_live/ui/live_view.dart';
import 'package:probashi_live/ui/profile_tab_view.dart';
import 'package:probashi_live/ui/shorts_tab_view.dart';
import 'package:probashi_live/ui/video_tab_view.dart';
import '../utils/socket_service.dart';
import 'home_tab_view.dart';
import 'message_tab_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedBottomNavIndex = 0;
  final socketService = SocketService.instance;

  final List<Widget> _pages = const [
    HomeTabView(),
    ShortsTabView(),
    VideoTabView(),
    MessageTabView(),
    ProfileTabView(),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSocket();

  }
  Future<void> _initSocket() async {
    final token = await FlutterSecureStorage().read(key: 'access_token');
    socketService.connect(token!);
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(index: _selectedBottomNavIndex, children: _pages),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: Colors.purple.shade900.withOpacity(0.9),
            notchMargin: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home, label: "Live", index: 0),
                _buildNavItem(
                  icon: Icons.camera_alt,
                  label: "Shorts",
                  index: 1,
                ),
                const SizedBox(width: 40),
                _buildNavItem(icon: Icons.message, label: "Message", index: 3),
                _buildNavItem(icon: Icons.person, label: "Profile", index: 4),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LivePage(),
                ),
              );
            },
            shape: const CircleBorder(),
            backgroundColor: Colors.amberAccent,
            child: const Icon(Icons.videocam, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.amberAccent : Colors.white70),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.amberAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


