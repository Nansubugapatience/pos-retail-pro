import 'package:drift/drift.dart';
import '../database/app_db.dart';

class ProductRepository {
  final AppDb db;
  ProductRepository(this.db);

  Stream<List<Product>> watchAll() => db.select(db.products).watch();

  Future<List<Product>> search(String q) => (db.select(db.products)
        ..where((p) => p.name.like('%$q%') | p.barcode.equals(q)))
      .get();

  Future<int> add(ProductsCompanion p) => db.into(db.products).insert(p);

  Future<bool> update(Product p) => db.update(db.products).replace(p);

  Future<int> delete(int id) =>
      (db.delete(db.products)..where((p) => p.id.equals(id))).go();

  Future<List<Product>> lowStock() => (db.select(db.products)
        ..where((p) => p.stockQty.isSmallerOrEqual(p.reorderLevel)))
      .get();
}
