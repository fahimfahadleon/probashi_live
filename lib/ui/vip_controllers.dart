import 'package:flutter/material.dart';
import 'package:probashi_live/models/collections_category.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import '../models/gift_category.dart';
import '../models/parchase_collection.dart';
import '../utils/api_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';

class VipControllers extends StatefulWidget {
  const VipControllers({super.key});

  @override
  State<VipControllers> createState() => _VipControllersState();
}

class _VipControllersState extends State<VipControllers>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final Map<String, SVGAAnimationController> _controllers = {};
  List<CollectionsCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> purchaseCollection(PurchaseCollectionRequest body) async {
    await ApiService.getApiClient().purchaseCollection(body);
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getApiClient()
          .getAllCategoriesWithCollections();
      if (mounted) {
        setState(() {
          _categories = categories;
          _tabController = TabController(
            length: _categories.length,
            vsync: this,
          );
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch categories: $e");
      if (mounted) setState(() => _loading = false);
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(child: Text("No gift categories found"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom header with back button and title
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Available Collections",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.diamond, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              "${Variables.currentUser?.diamond ?? 0}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab bar
                TabBar(
                  isScrollable: true,
                  controller: _tabController,
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.purple,
                  tabs: _categories.map((e) => Tab(text: e.name)).toList(),
                ),

                // The rest of your TabBarView etc...
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((category) {
                      final gifts = category.gifts;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          itemCount: gifts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    final currentDiamond =
                                        Variables.currentUser?.diamond ?? 0;
                                    if (currentDiamond >= gift.price) {
                                      final type =
                                          getCollectionTypeFromCategory(
                                            category.name,
                                          );
                                      PurchaseCollectionRequest body =
                                          PurchaseCollectionRequest(
                                            type: type,
                                            name: gift.name,
                                          );
                                      purchaseCollection(body);
                                    } else {
                                      Utils.showToast(
                                        context,
                                        "Not enough diamonds.",
                                      );
                                    }
                                  },
                                  onLongPress: () =>
                                      _showSVGAPreview(gift.imageUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      Variables.BASE_URL + gift.thumbnailUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${gift.price}💎",
                                  style: const TextStyle(fontSize: 12),
                                ),
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
    );
  }

  CollectionType getCollectionTypeFromCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'frame':
        return CollectionType.frame;
      case 'bubble':
        return CollectionType.bubble;
      case 'entrance':
        return CollectionType.entrance;
      default:
        throw Exception('Unknown category type');
    }
  }
}
