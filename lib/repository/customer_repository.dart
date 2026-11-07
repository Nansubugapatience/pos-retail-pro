import 'package:drift/drift.dart';
import '../database/app_db.dart';

class CustomerRepository {
  final AppDb db;
  CustomerRepository(this.db);

  Stream<List<Customer>> watchAll() => db.select(db.customers).watch();

  Future<List<Customer>> search(String q) => (db.select(db.customers)
        ..where((c) => c.name.like('%$q%') | c.phone.like('%$q%')))
      .get();

  Future<int> add(CustomersCompanion c) => db.into(db.customers).insert(c);

  Future<bool> update(Customer c) => db.update(db.customers).replace(c);

  Future<int> delete(int id) =>
      (db.delete(db.customers)..where((c) => c.id.equals(id))).go();
}
