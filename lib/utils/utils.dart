import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:probashi_live/utils/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';

import '../models/collection_name_request.dart';
import '../models/live_user.dart';
import '../models/user_profile.dart';
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

  static void printGreenComment(String comment) {
    const green = '\x1B[32m';   // ANSI code for green
    const reset = '\x1B[0m';    // Reset color
    debugPrint('$green $comment $reset');
  }

  static Future<UserRelation> toggleFollowStatus(UserProfile userProfile) async {
    try {
      if (userProfile.relation?.isFollowing == true) {
        await ApiService.getApiClient().unfollowUser(userProfile.id);
        return UserRelation(
          isFollowing: false,
          isFriend: userProfile.relation?.isFriend ?? false,
        );
      } else {
        await ApiService.getApiClient().followUser(userProfile.id);
        return UserRelation(
          isFollowing: true,
          isFriend: userProfile.relation?.isFriend ?? false,
        );
      }
    } catch (e) {
      print('Error toggling follow status: $e');
      return userProfile.relation ?? UserRelation(isFollowing: false, isFriend: false);

    }
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

  static String getActiveCollectionId(Map<String,dynamic>map, String activeCollection){
    final activeFrameId = map['active']?[activeCollection];
    final availableFrames = List<String>.from(map[activeCollection] ?? []);

    if (activeFrameId == null || !availableFrames.contains(activeFrameId)) {
      return ""; // Either no active frame or not in user's collection
    }

    return activeFrameId;

  }

  static void showMiniProfileDialog(UserProfile userProfile, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          MiniUserProfileDialog(
            userProfile: userProfile,
            onRelationToggle: () async {
              try {
                final newRelation = await Utils.toggleFollowStatus(userProfile);
                return newRelation;
              } catch (e) {
                print(e);
                return UserRelation(isFollowing: false, isFriend: false);
              }
            },
            onMessage: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatPage(
                        currentUserId: SocketService.instance.userId,
                        otherUserId: userProfile.id,
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

