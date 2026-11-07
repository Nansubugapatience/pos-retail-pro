import 'package:drift/drift.dart';
import '../database/app_db.dart';

class ReportRepository {
  final AppDb db;
  ReportRepository(this.db);

  Future<double> totalBetween(DateTime from, DateTime to) async {
    final sum = db.sales.total.sum();
    final q = db.selectOnly(db.sales)
      ..addColumns([sum])
      ..where(db.sales.createdAt.isBetweenValues(from, to));
    final row = await q.getSingle();
    return row.read(sum) ?? 0;
  }

  Future<int> countBetween(DateTime from, DateTime to) async {
    final cnt = db.sales.id.count();
    final q = db.selectOnly(db.sales)
      ..addColumns([cnt])
      ..where(db.sales.createdAt.isBetweenValues(from, to));
    final row = await q.getSingle();
    return row.read(cnt) ?? 0;
  }

  Future<List<MapEntry<String, int>>> topProducts({int limit = 5}) async {
    final qty = db.saleItems.qty.sum();
    final q = db.selectOnly(db.saleItems).join([
      innerJoin(
          db.products, db.products.id.equalsExp(db.saleItems.productId)),
    ])
      ..addColumns([db.products.name, qty])
      ..groupBy([db.products.id])
      ..orderBy([OrderingTerm.desc(qty)])
      ..limit(limit);
    final rows = await q.get();
    return rows
        .map((r) => MapEntry(r.read(db.products.name)!, r.read(qty) ?? 0))
        .toList();
  }
}
