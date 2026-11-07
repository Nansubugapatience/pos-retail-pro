import 'package:flutter/foundation.dart';
import '../database/app_db.dart';
import '../repository/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository repo;
  List<Customer> customers = [];

  CustomerProvider(this.repo) {
    repo.watchAll().listen((data) {
      customers = data;
      notifyListeners();
    });
  }

  Future<void> add(CustomersCompanion c) => repo.add(c);
  Future<void> update(Customer c) => repo.update(c);
  Future<void> remove(int id) => repo.delete(id);
}
