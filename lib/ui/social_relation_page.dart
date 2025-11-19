import 'package:flutter/material.dart';
import 'package:probashi_live/ui/cached_circle_avatar.dart';
import 'package:probashi_live/utils/variables.dart';
import '../models/user_profile.dart';
import '../models/user_relations_dto.dart';
import '../utils/api_service.dart';
import '../utils/utils.dart';

class SocialRelationsPage extends StatefulWidget {
  final int initialTab; // 1 = Friends, 2 = Followers, 3 = Following

  const SocialRelationsPage({super.key, required this.initialTab});

  @override
  State<SocialRelationsPage> createState() => _SocialRelationsPageState();
}

class _SocialRelationsPageState extends State<SocialRelationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserRelationsResponse? _relations;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Convert 1/2/3 → 0/1/2 safely
    final int index = (widget.initialTab - 1).clamp(0, 2);

    _tabController = TabController(length: 3, vsync: this, initialIndex: index);
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserRelationsResponse data = await ApiService.getApiClient()
          .getUserRelations(Variables.currentUser!.id);

      setState(() {
        _relations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load relations';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social Relations"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Friends"),
            Tab(text: "Followers"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: Text(_error!)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                RelationTab(
                  users: removeDuplicatedRelations(_relations?.friends),
                  defaultIsFollowing: true,
                ),
                RelationTab(
                  users: removeDuplicatedRelations(_relations?.followers),
                  defaultIsFollowing: false,
                ),
                RelationTab(
                  users: removeDuplicatedRelations(_relations?.following),
                  defaultIsFollowing: true,
                ),
              ],
            ),
    );
  }
}

List<UserRelationUser> removeDuplicatedRelations(List<UserRelationUser>? relations) {
  if(relations == null || relations.isEmpty){
    return [];
  }
  final seen = <String>{};
  return relations.where((r) => seen.add(r.id)).toList();
}

class UserProfileItem extends StatelessWidget {
  final UserRelationUser user;
  final VoidCallback onTap;

  const UserProfileItem({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0), // reduce horizontal padding
      leading: CachedCircleAvatar(
        imageUrl: user.profilePic,
        user: null,
        radius: 20,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // prevent extra vertical spacing
        children: [
          Text(
            user.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2), // small gap between name and id
          GestureDetector(
            onTap: () {
              Utils.copyToClipboard(user.id);
              Utils.showToast(context, "Id copied to clipboard!");
            },
            child: Text(
              'ID: ${user.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                decoration: TextDecoration.underline, // makes it clear it's clickable
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class RelationTab extends StatelessWidget {
  final List<UserRelationUser> users;
  final bool defaultIsFollowing;

  const RelationTab({
    super.key,
    required this.users,
    this.defaultIsFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: Text("No users")));
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final user = users[i];
          return UserProfileItem(
            user: user,
            onTap: () => Utils.showMiniProfileDialog(
              userProfile: UserProfile(
                id: user.id,
                name: user.name,
                profilePic: user.profilePic,
                vipStatus: user.vipStatus,
                coin: 0,
                diamond: 0,
                level: 1,
                isBlocked: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                relation: UserRelation(
                  isFollowing: defaultIsFollowing,
                  isFriend: false,
                ),
              ),
              context: context,
              // userRelationUser:
            ),
          );
        },
      ),
    );
  }
}
