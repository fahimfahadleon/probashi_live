// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_seller_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCoinSellerRequest _$CreateCoinSellerRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCoinSellerRequest(
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$CreateCoinSellerRequestToJson(
        CreateCoinSellerRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
    };

UserRequestModel _$UserRequestModelFromJson(Map<String, dynamic> json) =>
    UserRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$UserRequestModelToJson(UserRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

CoinSeller _$CoinSellerFromJson(Map<String, dynamic> json) => CoinSeller(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      nationalId: json['nationalId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: json['user'] == null
          ? null
          : UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      coinSendHistory: (json['coinSendHistory'] as List<dynamic>?)
          ?.map((e) => CoinSendHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CoinSellerToJson(CoinSeller instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'fullName': instance.fullName,
      'nationalId': instance.nationalId,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'user': instance.user?.toJson(),
      'coinSendHistory':
          instance.coinSendHistory?.map((e) => e.toJson()).toList(),
    };

SendCoinsRequest _$SendCoinsRequestFromJson(Map<String, dynamic> json) =>
    SendCoinsRequest(
      sellerId: json['sellerId'] as String,
      fromId: json['fromId'] as String,
      toUserId: json['toUserId'] as String,
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$SendCoinsRequestToJson(SendCoinsRequest instance) =>
    <String, dynamic>{
      'sellerId': instance.sellerId,
      'fromId': instance.fromId,
      'toUserId': instance.toUserId,
      'amount': instance.amount,
    };

SendResult _$SendResultFromJson(Map<String, dynamic> json) => SendResult(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SendResultToJson(SendResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

CoinSendHistory _$CoinSendHistoryFromJson(Map<String, dynamic> json) =>
    CoinSendHistory(
      id: json['id'] as String,
      fromSellerId: json['fromSellerId'] as String,
      fromSeller: json['fromSeller'] == null
          ? null
          : CoinSeller.fromJson(json['fromSeller'] as Map<String, dynamic>),
      toUserId: json['toUserId'] as String,
      toUser: json['toUser'] == null
          ? null
          : UserProfile.fromJson(json['toUser'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CoinSendHistoryToJson(CoinSendHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromSellerId': instance.fromSellerId,
      'fromSeller': instance.fromSeller,
      'toUserId': instance.toUserId,
      'toUser': instance.toUser,
      'amount': instance.amount,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ApplyCoinSellerRequest _$ApplyCoinSellerRequestFromJson(
        Map<String, dynamic> json) =>
    ApplyCoinSellerRequest(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      nationalId: json['nationalId'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$ApplyCoinSellerRequestToJson(
        ApplyCoinSellerRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'nationalId': instance.nationalId,
      'email': instance.email,
    };
