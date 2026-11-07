
import 'package:drift/drift.dart';
import 'db_tables.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [
  Users, BusinessProfile, Categories, Products, Customers,
  Sales, SaleItems, Payments, StockMovements, SyncQueue,
])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (d) async =>
            await customStatement('PRAGMA foreign_keys = ON'),
      );

  // Save a sale, its items and payment in one transaction
  Future<void> saveSale(SalesCompanion sale, List<SaleItemsCompanion> items,
      PaymentsCompanion payment) {
    return transaction(() async {
      final saleId = await into(sales).insert(sale);
      for (final i in items) {
        await into(saleItems).insert(i.copyWith(saleId: Value(saleId)));
        await customUpdate(
          'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
          variables: [
            Variable.withInt(i.qty.value),
            Variable.withInt(i.productId.value),
          ],
          updates: {products},
        );
      }
      await into(payments).insert(payment.copyWith(saleId: Value(saleId)));
    });
  }
}

QueryExecutor _open() => driftDatabase(
      name: 'pos_retail_pro',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );