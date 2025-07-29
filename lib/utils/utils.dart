import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';

import '../models/user_profile.dart';
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

}