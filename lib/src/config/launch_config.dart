/// Explicit build profile; language, IP address and region never grant access.
abstract final class LaunchConfig {
  static const profile = String.fromEnvironment('HILDORS_RELEASE_PROFILE', defaultValue: 'team');
  static const usFree = profile == 'us_free';
  static const customizationOrders = !usFree;
  static const creatorSettlement = !usFree;
  static const paidPurchases = !usFree;
  static const creatorCertification = true;
  static const freeCreatorPublishing = true;
}
