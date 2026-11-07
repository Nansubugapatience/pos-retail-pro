import 'package:drift/drift.dart';
import '../database/app_db.dart';
import '../provider/cart_provider.dart';

class SaleRepository {
  final AppDb db;
  SaleRepository(this.db);

  Future<void> checkout({
    required int userId,
    int? customerId,
    required List<CartLine> lines,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    required String method, // cash | card | mobile_money
    String? reference,
  }) {
    return db.saveSale(
      SalesCompanion.insert(
        userId: userId,
        subtotal: subtotal,
        total: total,
        customerId: Value(customerId),
        tax: Value(tax),
        discount: Value(discount),
      ),
      lines
          .map((l) => SaleItemsCompanion.insert(
                saleId: 0, // replaced inside saveSale
                productId: l.product.id,
                qty: l.qty,
                unitPrice: l.product.price,
              ))
          .toList(),
      PaymentsCompanion.insert(
        saleId: 0,
        method: method,
        amount: total,
        reference: Value(reference),
      ),
    );
  }

  Stream<List<Sale>> watchRecent() => (db.select(db.sales)
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(50))
      .watch();
}
