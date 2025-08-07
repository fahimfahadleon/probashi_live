import 'package:flutter/material.dart';
import 'package:probashi_live/models/user_profile.dart';
import 'package:probashi_live/ui/cached_network_box_image.dart';

import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';

import '../utils/api_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';

class MyCollections extends StatefulWidget {
  const MyCollections({super.key});

  @override
  State<MyCollections> createState() => _MyCollectionsScreenState();
}

class _MyCollectionsScreenState extends State<MyCollections> with TickerProviderStateMixin {
  Map<String, List<String>> myCollections = {};
  Map<String, String> activeCollections = {};

  final SVGAParser parser = SVGAParser();

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final Map<String, dynamic>? settings = Variables.currentUser?.settings;
    if (settings == null) return;

    // Parse my collections
    final categories = ['frame', 'bubble', 'entrance'];
    for (var cat in categories) {
      final raw = settings[cat];
      if (raw is List) {
        myCollections[cat] = raw.map((e) => e.toString()).toList();
      }
    }

    // Parse active collections
    final active = settings['active'];
    if (active is Map<String, dynamic>) {
      activeCollections = active.map((k, v) => MapEntry(k, v.toString()));
    }

    setState(() {});
  }






  Future<void> _showSVGAPreview(String urls) async {
    final controller = SVGAAnimationController(vsync: this);
    final url = Variables.BASE_URL + urls;

    final videoItem = await Utils.getCachedSvga(url);
    if (!mounted || videoItem == null) return;

    controller.videoItem = videoItem;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.reset();
              controller.repeat(count: 1).whenComplete(() {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(); // Close dialog when done
                }
              });
            });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: SVGAImage(controller),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  // Helper to update active collections and refresh UI
  void _setActiveCollection(String category, String collectionId) {
    setState(() {
      activeCollections[category] = collectionId;
    });
  }

  Widget _buildActiveSection() {
    final categories = ['frame', 'bubble', 'entrance'];

    List<Widget> categoryWidgets = [];

    for (var category in categories) {
      final activeId = activeCollections[category];

      Widget content;

      if (activeId != null && activeId.isNotEmpty) {
        content = FutureBuilder<Map<String, String>?>(
          future: Utils.getThumbAndSvgaUrl(activeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: 80,
                height: 100,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return SizedBox(
                width: 80,
                height: 100,
                child: Center(child: Icon(Icons.error, color: Colors.red)),
              );
            }

            final thumbnailUrl = Variables.BASE_URL + snapshot.data!['thumbnailUrl']!;
            final imageUrl = snapshot.data!['imageUrl'];

            return GestureDetector(
              onLongPress: () {
                if (imageUrl != null) {
                  _showSVGAPreview(imageUrl);
                }
              },
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purpleAccent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        content = SizedBox(
          width: 80,
          height: 100,
          child: Center(
            child: Text(
              'Nothing is active',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        );
      }

      categoryWidgets.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton(
                onPressed: () {  },
                child: const Text(
                  "",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
          Spacer(),
          Center(
            child: Text(
                  "ACTIVE COLLECTIONS",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
          ),
              Spacer(),
              TextButton(
                onPressed: () {
                  _saveActiveCollectionsLocally();
                },
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: categoryWidgets,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }


  Future<void> _saveActiveCollectionsLocally() async {
    try {
      final currentUser = Variables.currentUser;
      if (currentUser == null) {
        print('No current user found!');
        return;
      }

      Map<String, dynamic> settings;
      if (currentUser.settings != null && currentUser.settings is Map<String, dynamic>) {
        settings = Map<String, dynamic>.from(currentUser.settings!);
      } else {
        settings = {};
      }

      settings['active'] = {
        'frame': activeCollections['frame'] ?? '',
        'bubble': activeCollections['bubble'] ?? '',
        'entrance': activeCollections['entrance'] ?? '',
      };

      print('Updated settings: $settings');


      UserProfile profile = await ApiService.getApiClient().updateUserSettings(settings: settings);
      Variables.currentUser = profile;
    } catch (e) {
      print('Error updating active collections locally: $e');
    }
  }


  Widget _buildCollectionItem(String name, bool isActive, String category) {
    return FutureBuilder<Map<String, String>?>(
      future: Utils.getThumbAndSvgaUrl(name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            width: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
            height: 100,
            width: 80,
            child: Center(child: Icon(Icons.error, color: Colors.red)),
          );
        }

        final thumbnailUrl = Variables.BASE_URL + snapshot.data!['thumbnailUrl']!;
        final imageUrl = snapshot.data!['imageUrl'];

        return GestureDetector(
          onTap: () {
            _setActiveCollection(category, name);
          },
          onLongPress: () {
            if (imageUrl != null) {
              _showSVGAPreview(imageUrl);
            }
          },
          child: Card(
            shape: isActive
                ? RoundedRectangleBorder(
                side: const BorderSide(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8))
                : null,
            child: Column(
              children: [
                CachedNetworkImageBox(imageUrl: thumbnailUrl,height: 60,width: 60,),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 12)),
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final diamonds = Variables.currentUser?.diamond ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Title text
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "My Collections",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Diamonds count on far right
                    Row(
                      children: [
                        const Icon(Icons.diamond, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          '$diamonds',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Body content scrollable area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Active Collections Section
                    _buildActiveSection(),

                    const SizedBox(height: 12),


                    Center(
                      child: const Text(
                        "MY COLLECTIONS",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Collections Sections (frame, bubble, entrance)
                    ...['frame', 'bubble', 'entrance'].map((category) {
                      final items = myCollections[category] ?? [];
                      final activeId = activeCollections[category];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            const Text('No items available', style: TextStyle(color: Colors.grey)),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // reduced padding
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SizedBox(
                              height: 106,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: items.map((item) {
                                  final isActive = item == activeId;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8), // less space between thumbnails
                                    child: _buildCollectionItem(item, isActive, category),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
