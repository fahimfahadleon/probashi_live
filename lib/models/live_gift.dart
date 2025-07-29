import 'package:json_annotation/json_annotation.dart';

part 'live_gift.g.dart';

@JsonSerializable()
class LiveGift {
  final String toUserId;
  final String sessionId;
  final String giftId;

  LiveGift({
    required this.toUserId,
    required this.sessionId,
    required this.giftId,
  });

  factory LiveGift.fromJson(Map<String, dynamic> json) =>
      _$LiveGiftFromJson(json);

  Map<String, dynamic> toJson() => _$LiveGiftToJson(this);
}