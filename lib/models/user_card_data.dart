class UserCardData {
  final int id;
  final String name;
  final List<String> tags;
  final int views;
  final bool isLive;
  final String imageUrl;

  UserCardData({
    required this.id,
    required this.name,
    required this.tags,
    required this.views,
    required this.isLive,
    required this.imageUrl,
  });
}