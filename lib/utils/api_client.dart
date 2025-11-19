
import 'package:dio/dio.dart';
import 'package:probashi_live/models/collection_name_request.dart';
import 'package:probashi_live/models/collections_category.dart';
import 'package:retrofit/http.dart';
import 'dart:async';
import '../models/announcement_model.dart';
import '../models/coin_seller_models.dart';
import '../models/create_payment_dto.dart';

import '../models/friend_user_model.dart';
import '../models/gift_category.dart';
import '../models/login_response.dart';
import '../models/offer.dart';
import '../models/parchase_collection.dart';
import '../models/settings_model.dart';
import '../models/user_profile.dart';
import '../models/user_relations_dto.dart';
import '../models/vip_diamond_pack.dart';

part 'api_client.g.dart';
@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @POST("/auth/google")//used
  Future<LoginResponse> loginWithGoogle(@Body() Map<String, dynamic> body);

  @GET("/profile/me")//used
  Future<UserProfile> getMyProfile();

//used
  @GET("/profile/{id}")
  Future<UserProfile> getUserProfile(@Path("id") String userId);

  //used
  @GET("/friends/stats/{id}")
  Future<UserStats> getUserStats(@Path("id") String userId);

  //used
  @POST("/payment/request-payment")
  Future<void> requestPayment(@Body() CreatePaymentDto dto);

  //used
  @GET("/announcement/get-all")
  Future<List<Announcement>> getAllAnnouncements();



//used
  @POST("/friends/follow/{userId}")
  Future<UserRelationUser> followUser(@Path("userId") String userId);

  //used
  @DELETE("/friends/unfollow/{userId}")
  Future<UserRelationUser> unfollowUser(@Path("userId") String userId);

//used
  @GET("/gifts/by-category")
  Future<List<Category>> getAllCategoriesWithGifts();

  //used
  @GET("/collections/by-category")
  Future<List<CollectionsCategory>> getAllCategoriesWithCollections();
//used
  @POST("/collections/purchase")
  Future<UserProfile> purchaseCollection(
      @Body() PurchaseCollectionRequest body,);
//used
  @POST('/collections/by-name')
  Future<String> getCollectionSvgaByName(@Body() CollectionNameRequest request);

//used
  @PATCH('/profile/settings')
  Future<UserProfile> updateUserSettings({
    @Body() required Map<String, dynamic> settings,
  });

  //used
  @GET("/settings/get-settings")
  Future<Settings> getSettings();

  //used
  @GET("/coin-seller/{id}")
  Future<CoinSeller> getSellerById(@Path("id") String id);

  // ✅ Send Coins
  @POST("/coin-seller/send")
  Future<SendResult> sendCoins(@Body() SendCoinsRequest body);

  // ✅ Get Send History
  @GET("/coin-seller/{id}/history")
  Future<List<CoinSendHistory>> getSendHistory(@Path("id") String id);

  //used
  @POST("/coin-seller-request/apply")
  Future<void> applyAsCoinSeller(@Body() ApplyCoinSellerRequest body);

  @GET("/coin-seller-request/user/{userId}")
  Future<UserRequestModel> getUserRequest(@Path("userId") String userId);


  @GET('/friends/{id}/relations')
  Future<UserRelationsResponse> getUserRelations(
      @Path('id') String userId,
      );
  // VIP Packs
  @GET("/vip/diamond-pack")
  Future<List<ProductVipPackDto>> getVipPacks();

  @DELETE("/vip/diamond-pack/{id}")
  Future<void> deleteVipPack(@Path("id") String id);

  // Offers
  @GET("/vip/offer")
  Future<List<ProductOfferDto>> getOffers();


  @DELETE("/vip/offer/{id}")
  Future<void> deleteOffer(@Path("id") String id);


  // ----------------- Payments -----------------
  @POST("/payment/request-payment")
  Future<PaymentDto> createPayment(@Body() CreatePaymentDto dto);

  @GET("/payment/all")
  Future<List<PaymentDto>> getAllPayments();

  @POST("/friends/report")
  Future<void> submitReport(@Body() CreateReportDto dto);


}