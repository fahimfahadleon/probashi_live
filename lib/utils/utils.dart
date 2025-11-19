import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:probashi_live/utils/socket_service.dart';
import 'package:probashi_live/utils/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';

import '../models/collection_name_request.dart';
import '../models/friend_user_model.dart';
import '../models/live_user.dart';
import '../models/settings_model.dart';
import '../models/user_profile.dart';
import '../models/user_relations_dto.dart' hide UserRelation;
import '../ui/mini_user_profile_dialog.dart';
import '../ui/one_to_one_chat.dart';
import '../ui/svga_overlay.dart';
import 'api_service.dart';

class Utils{
  static showToast(BuildContext context,String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  static void printGreenComment(String comment) {
    const green = '\x1B[32m';   // ANSI code for green
    const reset = '\x1B[0m';    // Reset color
    debugPrint('$green $comment $reset');
  }



  static requestPermission(BuildContext context) async {
    // Example: Request multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted  && statuses[Permission.microphone]!.isGranted) {

    }
  }

  static Future<File> downloadAndCacheSvga(String url, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    if (await file.exists()) {
      return file; // file already cached
    }

    final dio = Dio();
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    await file.writeAsBytes(response.data!);
    return file;
  }

  static Future<MovieEntity?> getCachedSvga(String url) async {
    final filename = url.split('/').last;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    if (!await file.exists()) {
      // Download and save file
      final response = await HttpClient().getUrl(Uri.parse(url))
          .then((req) => req.close());

      if (response.statusCode != 200) return null;

      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
    }

    final bytes = await file.readAsBytes();
    final videoItem = await SVGAParser.shared.decodeFromBuffer(bytes);
    return videoItem;
  }


  static List<LiveUser> addLiveUsersWithoutDuplicates(
      List<LiveUser> list, List<LiveUser> newItems) {
    final existingIds = list.map((e) => e.id).toSet();

    for (final item in newItems) {
      if (!existingIds.contains(item.id)) {
        list.add(item);
        existingIds.add(item.id);
      }
    }

    return list;
  }




  static Future<Map<String, String>?> getThumbAndSvgaUrl(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'svga_$collectionName';
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        final cachedData = {
          'imageUrl': data['imageUrl'] as String,
          'thumbnailUrl': data['thumbnailUrl'] as String,
        };
        return cachedData;
      } catch (e) {
        await prefs.remove(cacheKey);
      }
    }
    try {
      final request = CollectionNameRequest(collectionName);
      final response = await ApiService.getApiClient().getCollectionSvgaByName(request);
      final Map<String, dynamic> data = jsonDecode(response);
      final freshData = {
        'imageUrl': data['imageUrl'] as String,
        'thumbnailUrl': data['thumbnailUrl'] as String,
      };
      await prefs.setString(cacheKey, jsonEncode(data));
      return freshData;
    } catch (e) {
      return null;
    }
  }



  static void showReportDialog(BuildContext context, String targetId) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Report'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Your Email',
                        hintText: 'example@mail.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Describe the issue',
                      ),
                      maxLines: 3,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Reason required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;

                  setState(() => isLoading = true);

                  try {
                    final reportDto = CreateReportDto(
                      email: emailController.text.trim(),
                      reason: reasonController.text.trim(),
                      targetId: targetId,
                    );

                    await ApiService.getApiClient().submitReport(reportDto);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report submitted successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text('Submit'),
              )
            ],
          );
        },
      ),
    );
  }




  static String getActiveCollectionId(Map<String,dynamic>map, String activeCollection){
    final activeFrameId = map['active']?[activeCollection];
    final availableFrames = List<String>.from(map[activeCollection] ?? []);

    if (activeFrameId == null || !availableFrames.contains(activeFrameId)) {
      return ""; // Either no active frame or not in user's collection
    }

    return activeFrameId;

  }
  static Future<Settings?> fetchSettings() async {
    try {
      return await ApiService.getApiClient().getSettings();
    } catch (e) {
      print('Error fetching settings: $e');
      return null;
    }
  }


// Toggle follow/friend status for a user
  static Future<UserRelation> toggleFollowStatus({
    required String targetUserId,
    UserRelation? existingRelation,
  }) async {
    try {
      final api = ApiService.getApiClient();

      // If already following/friend → unfollow
      if (existingRelation?.isFollowing == true) {
        await api.unfollowUser(targetUserId);
        return UserRelation(
          isFollowing: false,
          isFriend: false,
        );
      }

      // Otherwise, follow
      final newRelationUser = await api.followUser(targetUserId);

      // Extract relation info from DTO
      final isFollowing = newRelationUser.relation.isFollowing;
      final isFriend = newRelationUser.relation.isFriend;

      return UserRelation(
        isFollowing: isFollowing,
        isFriend: isFriend,
      );
    } catch (e) {
      print('Error toggling follow status: $e');
      return existingRelation ?? UserRelation(isFollowing: false, isFriend: false);
    }
  }

// Show mini profile dialog for either UserProfile or UserRelationUser
  static void showMiniProfileDialog({
    required BuildContext context,
    UserProfile? userProfile,
    UserRelationUser? userRelationUser,
  }) {
    // Convert UserRelationUser to UserProfile if needed
    final profile = userProfile ??
        (userRelationUser != null
            ? UserProfile(
          id: userRelationUser.id,
          name: userRelationUser.name,
          profilePic: userRelationUser.profilePic,
          vipStatus: userRelationUser.vipStatus,
          coin: 0,
          diamond: 0,
          level: 1,
          isBlocked: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          relation: UserRelation(
            isFollowing: userRelationUser.relation.isFollowing,
            isFriend: userRelationUser.relation.isFriend,
          ),
        )
            : null);

    if (profile == null) return;

    showDialog(
      context: context,
      builder: (_) => MiniUserProfileDialog(
        userProfile: profile,
        onRelationToggle: () async {
          return await toggleFollowStatus(
            targetUserId: profile.id,
            existingRelation: profile.relation,
          );
        },
        onMessage: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                currentUserId: Variables.currentUser!.id,
                otherUserId: profile.id,
              ),
            ),
          );
        },
      ),
    );
  }

  static void handleUserJoined(BuildContext context, UserProfile user) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          top: screenHeight / 3, // 1/3 from the top
          left: 0,
          right: 0,
          child: Center(
            child: SVGAOverlay(
              userSettings: user,
              collectionType: 'bubble', // or whichever type you want
              width: 300,
              height: 80,
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }




}

