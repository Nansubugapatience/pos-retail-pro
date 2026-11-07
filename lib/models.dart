// Data models. toJson/fromJson let us save everything locally (offline support).

class Product {
  String id, name, category;
  int price, stock, reorder;
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.reorder,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'reorder': reorder,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        category: j['category'],
        price: j['price'],
        stock: j['stock'],
        reorder: j['reorder'],
      );
}

class Customer {
  String id, name, phone;
  Customer({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  factory Customer.fromJson(Map<String, dynamic> j) =>
      Customer(id: j['id'], name: j['name'], phone: j['phone']);
}

class SaleItem {
  final String name;
  final int price, qty;
  SaleItem(this.name, this.price, this.qty);

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'qty': qty};

  factory SaleItem.fromJson(Map<String, dynamic> j) =>
      SaleItem(j['name'], j['price'], j['qty']);
}

class Sale {
  final String id, customer, method;
  final List<SaleItem> items;
  final int subtotal, tax, total;
  final DateTime time;
  bool synced; // false = made offline, waiting to upload to a server

  Sale({
    required this.id,
    required this.customer,
    required this.method,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.time,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer': customer,
        'method': method,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'time': time.toIso8601String(),
        'synced': synced,
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'],
        customer: j['customer'],
        method: j['method'],
        items: (j['items'] as List)
            .map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        subtotal: j['subtotal'],
        tax: j['tax'],
        total: j['total'],
        time: DateTime.parse(j['time']),
        synced: j['synced'] ?? false,
      );
}
