import 'package:flutter/material.dart';

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

}