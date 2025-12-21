import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:probashi_live/ui/live_view.dart';
import 'package:probashi_live/ui/participant_page.dart';
import 'package:probashi_live/ui/profile_tab_view.dart';
import 'package:probashi_live/ui/shorts_tab_view.dart';
import 'package:probashi_live/ui/social_login_page.dart';
import 'package:probashi_live/ui/video_tab_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/user_profile.dart';
import '../services/generic_system_service.dart';
import '../utils/api_service.dart';
import '../utils/permission_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';
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
  bool _hasNewMessage = false;

  final List<Widget> _pages = const [
    HomeTabView(),
    ShortsTabView(),
    VideoTabView(),
    ChatInboxPage(),
    ProfileTabView(),
  ];

  bool _socketConnected = false;

  @override
  void initState() {
    super.initState();
    PermissionService.requestPermission(
      context,
      onGranted: () {
        GenericStreamService.initialize();
      },
      onDenied: () {
        Utils.showSnackbar(context, "Permission Denied");
      },
    );
    _initSocket();
    WakelockPlus.enable();
  }




  Future<void> _initSocket() async {
    final token = await FlutterSecureStorage().read(key: 'access_token');
    if (token != null) {
      UserProfile profile = await ApiService.getApiClient().getMyProfile();
      if(profile.isBlocked){
        await FlutterSecureStorage().delete(key: 'access_token');
        Utils.showSnackbar(context, "Your account is blocked");
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>SocialLoginPage()),
        );
        return;
      }
      Variables.currentUser = profile;
      socketService.connect(token);
      socketService.socket.on('connected', (data) async {
        debugPrint('Socket connected: ${data['message']}');

        setState(() {
          _socketConnected = true;
        });
      });
      socketService.onNewMessage((message){
        if (_selectedBottomNavIndex != 3) {
          setState(() {
            _hasNewMessage = true;
          });
        }
      });
      SocketService.instance.onLiveInvite((inviteData) {
        final from = inviteData['fromUserId'];
        final sessionId = inviteData['sessionId'];
        final to = inviteData['toUserId'];
        final message = inviteData['message'];

        // Show popup or navigate to invite screen
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Live Invite"),
            content: Text("User $from invited you to join live session."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ParticipantPage(from: from, to: to, sessionId: sessionId)),
                  );
                },
                child: Text("Join"),
              ),
              TextButton(
                onPressed: (){
                  socketService.cancelInvite(fromUserId: from, toUserId: to, sessionId: sessionId);
                  Navigator.of(context).pop();
                },
                child: Text("Decline"),
              ),
            ],
          ),
        );
      });

      SocketService.instance.onInvitationAcceptedCallback((payload) async {
        print('payload: $payload');

        // 3️⃣ Close the dialog (pop it)
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // 1️⃣ Show a loading dialog first
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        // 2️⃣ Wait for variables to be set or just a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();

        // 4️⃣ Navigate to ParticipantPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParticipantPage(
              from: payload.fromUser,
              to: payload.userId,
              sessionId: payload.sessionId,
            ),
          ),
        );
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      if (index == 3) _hasNewMessage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_socketConnected) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

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
                _buildNavItem(icon: Icons.videogame_asset, label: "Games", index: 1),
                const SizedBox(width: 40),
                _buildNavItem(
                  icon: Icons.message,
                  label: "Message",
                  index: 3,
                  showDot: _hasNewMessage,
                ),
                _buildNavItem(icon: Icons.person, label: "Profile", index: 4),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LivePage()),
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
    bool showDot = false,
  }) {
    final isSelected = _selectedBottomNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(icon, color: isSelected ? Colors.amberAccent : Colors.white70),
              if (showDot)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
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
