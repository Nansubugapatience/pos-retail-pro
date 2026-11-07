import 'package:flutter/foundation.dart';
import '../database/app_db.dart';
import '../repository/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository repo;
  List<Product> products = [];

  ProductProvider(this.repo) {
    repo.watchAll().listen((data) {
      products = data;
      notifyListeners();
    });
  }

  Future<void> add(ProductsCompanion p) => repo.add(p);
  Future<void> update(Product p) => repo.update(p);
  Future<void> remove(int id) => repo.delete(id);
}
