import 'character_entitlement_repository.dart';
import 'customization_order_repository.dart';

class CustomizationRefundService {
  const CustomizationRefundService({
    required this.orders,
    required this.entitlements,
  });

  final CustomizationOrderRepository orders;
  final CharacterEntitlementRepository entitlements;

  Future<bool> completeVerifiedRefund({
    required String orderId,
    required String refundReference,
  }) async {
    await orders.recordVerifiedRefund(
      orderId: orderId,
      refundReference: refundReference,
    );
    final matching = (await orders.loadOrders())
        .where((candidate) => candidate.id == orderId);
    if (matching.isEmpty || matching.first.status != '已退款') return false;
    await entitlements.revoke('custom-$orderId');
    return true;
  }
}
