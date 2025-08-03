import 'package:shared_preferences/shared_preferences.dart';

class SvgaUrlCache {
  static const _cacheKeyPrefix = 'svga_url_';

  /// Get cached SVGA URL by collection name
  static Future<String?> getCachedUrl(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKeyPrefix + collectionName);
  }

  /// Save SVGA URL in cache
  static Future<void> cacheUrl(String collectionName, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyPrefix + collectionName, url);
  }
}
