import 'package:flutter/foundation.dart';
import '../database/app_db.dart';

class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, this.qty);
  double get total => product.price * qty;
}

class CartProvider extends ChangeNotifier {
  final List<CartLine> lines = [];
  double taxRate = 0;
  double discount = 0;

  double get subtotal => lines.fold(0, (s, l) => s + l.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax - discount;

  void add(Product p) {
    final i = lines.indexWhere((l) => l.product.id == p.id);
    i == -1 ? lines.add(CartLine(p, 1)) : lines[i].qty++;
    notifyListeners();
  }

  void remove(Product p) {
    lines.removeWhere((l) => l.product.id == p.id);
    notifyListeners();
  }

  void clear() {
    lines.clear();
    discount = 0;
    notifyListeners();
  }
}
