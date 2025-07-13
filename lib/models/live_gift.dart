import 'package:json_annotation/json_annotation.dart';
import 'live_user.dart';

part 'live_gift.g.dart';

@JsonSerializable(explicitToJson: true)
class LiveGift {
  final String id;
  final LiveUser fromUser;
  final LiveUser toUser;
  final String giftType;
  final int diamondCount;
  final DateTime createdAt;

  LiveGift({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.giftType,
    required this.diamondCount,
    required this.createdAt,
  });

  factory LiveGift.fromJson(Map<String, dynamic> json) =>
      _$LiveGiftFromJson(json);

  Map<String, dynamic> toJson() => _$LiveGiftToJson(this);
}
