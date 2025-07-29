import 'package:flutter/material.dart';
import 'package:probashi_live/models/gift_category.dart';
import 'package:probashi_live/utils/api_service.dart';
import 'package:probashi_live/utils/utils.dart';
import 'package:probashi_live/utils/variables.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

import '../models/gift.dart';

class GiftDialog extends StatefulWidget {
  final void Function(Gift gift)? onGiftClick;

  const GiftDialog({super.key, this.onGiftClick});

  @override
  State<GiftDialog> createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog> with TickerProviderStateMixin {
  TabController? _tabController;
  final Map<String, SVGAAnimationController> _controllers = {};
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getApiClient().getAllCategoriesWithGifts();
      if (mounted) {
        setState(() {
          _categories = categories;
          _tabController = TabController(length: _categories.length, vsync: this);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch categories: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSVGAPreview(String url) async {
    final controller = SVGAAnimationController(vsync: this);
    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(Variables.BASE_URL + url);
      controller.videoItem = videoItem;
      controller.repeat();

      // Show the preview dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 200,
              height: 200,
              child: SVGAImage(controller),
            ),
          ),
        ),
      ).then((_) {
        controller.dispose();
      });
    } catch (e) {
      debugPrint("Preview SVGA failed: $e");
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 540,
        width: MediaQuery.of(context).size.width * 0.9,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(child: Text("No gift categories found"))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Diamonds
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Gifts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        "${Variables.currentUser?.diamond ?? 0}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tabs
            TabBar(
              isScrollable: true,
              controller: _tabController,
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              tabs: _categories.map((e) => Tab(text: e.name)).toList(),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  final gifts = category.gifts;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      itemCount: gifts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (_, index) {
                        final gift = gifts[index];

                        return Column(
                          children: [
                            Text(
                              gift.name,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                final currentDiamond = Variables.currentUser?.diamond ?? 0;
                                if (currentDiamond >= gift.price) {
                                  widget.onGiftClick?.call(gift);
                                  Navigator.pop(context);
                                } else {
                                  Utils.showToast(context, "Not enough diamonds.");
                                }
                              },
                              onLongPress: () => _showSVGAPreview(gift.imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  Variables.BASE_URL + gift.thumbnailUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 32),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("${gift.price}💎", style: const TextStyle(fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
