import 'package:json_annotation/json_annotation.dart';
import 'package:probashi_live/models/user_profile.dart';

part 'coin_seller_models.g.dart';

@JsonSerializable()
class CreateCoinSellerRequest {
  final String name;
  final String email;

  CreateCoinSellerRequest({required this.name, required this.email});

  factory CreateCoinSellerRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCoinSellerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCoinSellerRequestToJson(this);
}



@JsonSerializable()
class UserRequestModel {
  final String id;
  final String userId;
  final String status;
  final String createdAt;

  UserRequestModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory UserRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UserRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserRequestModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CoinSeller {
  final String id;
  final String userId;
  final String fullName;
  final String nationalId;
  final String phoneNumber;
  final String email;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  final UserProfile? user; // nested User object
  final List<CoinSendHistory>? coinSendHistory; // relation list

  CoinSeller({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.nationalId,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.coinSendHistory,
  });

  factory CoinSeller.fromJson(Map<String, dynamic> json) =>
      _$CoinSellerFromJson(json);

  Map<String, dynamic> toJson() => _$CoinSellerToJson(this);
}


@JsonSerializable()
class SendCoinsRequest {
  final String sellerId;
  final String fromId;
  final String toUserId;
  final int amount;

  SendCoinsRequest({
    required this.sellerId,
    required this.fromId,
    required this.toUserId,
    required this.amount,
  });

  factory SendCoinsRequest.fromJson(Map<String, dynamic> json) =>
      _$SendCoinsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendCoinsRequestToJson(this);
}

@JsonSerializable()
class SendResult {
  final bool success;
  final String message;

  SendResult({required this.success, required this.message});

  factory SendResult.fromJson(Map<String, dynamic> json) =>
      _$SendResultFromJson(json);
  Map<String, dynamic> toJson() => _$SendResultToJson(this);
}


@JsonSerializable()
class CoinSendHistory {
  final String id;

  final String fromSellerId;
  final CoinSeller? fromSeller;

  final String toUserId;
  final UserProfile? toUser;

  final int amount;
  final DateTime createdAt;

  CoinSendHistory({
    required this.id,
    required this.fromSellerId,
    this.fromSeller,
    required this.toUserId,
    this.toUser,
    required this.amount,
    required this.createdAt,
  });

  factory CoinSendHistory.fromJson(Map<String, dynamic> json) =>
      _$CoinSendHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$CoinSendHistoryToJson(this);
}


@JsonSerializable()
class ApplyCoinSellerRequest {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String nationalId;
  final String email;

  ApplyCoinSellerRequest({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.nationalId,
    required this.email,
  });

  factory ApplyCoinSellerRequest.fromJson(Map<String, dynamic> json) =>
      _$ApplyCoinSellerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApplyCoinSellerRequestToJson(this);
}
