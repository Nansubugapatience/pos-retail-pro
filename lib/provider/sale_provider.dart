import 'package:flutter/foundation.dart';
import '../repository/sale_repository.dart';
import 'cart_provider.dart';

class SaleProvider extends ChangeNotifier {
  final SaleRepository repo;
  SaleProvider(this.repo);

  bool busy = false;

  Future<void> pay({
    required CartProvider cart,
    required int userId,
    int? customerId,
    required String method,
    String? reference,
  }) async {
    busy = true;
    notifyListeners();
    await repo.checkout(
      userId: userId,
      customerId: customerId,
      lines: cart.lines,
      subtotal: cart.subtotal,
      tax: cart.tax,
      discount: cart.discount,
      total: cart.total,
      method: method,
      reference: reference,
    );
    cart.clear();
    busy = false;
    notifyListeners();
  }
}
