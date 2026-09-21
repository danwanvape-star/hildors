import 'cloud_business_intake.dart';

/// Implement with StoreKit / Play Billing. No USD conversion or client-side
/// payment verification belongs here. Disabled until native adapters are ready.
class CustomStoreOffer {
  const CustomStoreOffer(
      {required this.productId, required this.localizedPrice});
  final String productId, localizedPrice;
}

abstract class CustomStoreBilling {
  String get platform;
  bool get testMode;
  Future<CustomStoreOffer?> product(String productId);
  Future<String?> purchase(CustomStoreOffer offer, String orderId);
  Future<List<String>> restore(String productId, String orderId);
}

class UnavailableCustomStoreBilling implements CustomStoreBilling {
  @override
  String get platform => 'unavailable';
  @override
  bool get testMode => false;
  @override
  Future<CustomStoreOffer?> product(String productId) async => null;
  @override
  Future<String?> purchase(CustomStoreOffer offer, String orderId) async =>
      throw const CloudApiException('PAYMENT_NOT_READY');
  @override
  Future<List<String>> restore(String productId, String orderId) async =>
      throw const CloudApiException('PAYMENT_NOT_READY');
}
