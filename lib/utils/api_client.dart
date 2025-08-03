
import 'package:dio/dio.dart';
import 'package:probashi_live/models/collections_category.dart';
import 'package:retrofit/http.dart';
import 'dart:async';
import '../models/announcement_model.dart';
import '../models/create_payment_dto.dart';
import '../models/gift_category.dart';
import '../models/login_response.dart';
import '../models/offer.dart';
import '../models/parchase_collection.dart';
import '../models/user_profile.dart';
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
  @GET("/vip/diamond-pack")
  Future<List<VIPDiamondPack>> getDiamondPacks();


  //used
  @GET("/announcement/get-all")
  Future<List<Announcement>> getAllAnnouncements();

//used
  @GET("/offer/get-all")
  Future<List<Offer>> getOffers();


  @POST("/friends/follow/{userId}")
  Future<void> followUser(@Path("userId") String userId);

  @DELETE("/friends/unfollow/{userId}")
  Future<void> unfollowUser(@Path("userId") String userId);


  @GET("/gifts/by-category")
  Future<List<Category>> getAllCategoriesWithGifts();

  @GET("/collections/by-category")
  Future<List<CollectionsCategory>> getAllCategoriesWithCollections();

  @POST("/collections/purchase")
  Future<void> purchaseCollection(
      @Body() PurchaseCollectionRequest body,);

}