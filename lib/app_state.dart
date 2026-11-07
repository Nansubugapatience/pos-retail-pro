import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

String money(int n) =>
    'UGX ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

// ───────────────────────── SECURITY ─────────────────────────
// Passwords are never stored in plain text. We store a random salt and a
// slowed-down SHA-256 hash, inside the device's encrypted keystore/keychain.
class Auth {
  static const _s = FlutterSecureStorage();

  static String _hash(String pw, String salt) {
    List<int> d = utf8.encode('$salt$pw');
    for (var i = 0; i < 5000; i++) {
      d = sha256.convert(d + utf8.encode(salt)).bytes;
    }
    return base64Encode(d);
  }

  static Future<bool> hasAccount() async => (await _s.read(key: 'email')) != null;

  static Future<String?> email() => _s.read(key: 'email');

  static Future<void> register(String email, String pw) async {
    final rnd = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await _s.write(key: 'email', value: email.trim().toLowerCase());
    await _s.write(key: 'salt', value: salt);
    await _s.write(key: 'hash', value: _hash(pw, salt));
  }

  static Future<bool> login(String email, String pw) async {
    final e = await _s.read(key: 'email');
    final salt = await _s.read(key: 'salt');
    final h = await _s.read(key: 'hash');
    if (e == null || salt == null || h == null) return false;
    return e == email.trim().toLowerCase() && h == _hash(pw, salt);
  }

  static Future<bool> changePassword(String oldPw, String newPw) async {
    final e = await _s.read(key: 'email');
    if (e == null || !await login(e, oldPw)) return false;
    await register(e, newPw);
    return true;
  }

  static Future<void> wipe() => _s.deleteAll();
}

// ───────────────────────── APP STATE ─────────────────────────
class AppState extends ChangeNotifier {
  SharedPreferences? _p;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  // Customization settings
  String businessName = 'My Store';
  String businessType = 'Retail Store';
  int colorValue = 0xFF1E5EFF;
  int taxRate = 18; // percent
  int defaultReorder = 10;
  bool dark = false;

  // Connectivity
  bool offline = false;

  // Data
  List<Product> products = [];
  List<Customer> customers = [];
  List<Sale> sales = [];

  // Current sale
  final Map<String, int> cart = {}; // productId -> quantity
  Customer? customer;

  // ── startup: load saved data (works with no internet) ──
  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString('data');
    if (raw == null) {
      _seed();
      await _save();
    } else {
      _load(jsonDecode(raw) as Map<String, dynamic>);
    }

    offline = _isOff(await Connectivity().checkConnectivity());
    // Event-based listener (no polling) = good for battery life.
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      final off = _isOff(r);
      if (off != offline) {
        offline = off;
        if (!off) syncPending();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  bool _isOff(List<ConnectivityResult> r) =>
      r.every((e) => e == ConnectivityResult.none);

  void _seed() {
    products = [
      Product(id: '1', name: 'Coca Cola 500ml', category: 'Beverages', price: 2500, stock: 50, reorder: 20),
      Product(id: '2', name: 'Sprite 500ml', category: 'Beverages', price: 2500, stock: 40, reorder: 20),
      Product(id: '3', name: 'Water 500ml', category: 'Beverages', price: 1500, stock: 100, reorder: 30),
      Product(id: '4', name: 'Bread', category: 'Groceries', price: 3000, stock: 30, reorder: 10),
      Product(id: '5', name: 'Chips', category: 'Snacks', price: 2000, stock: 45, reorder: 15),
    ];
    customers = [
      Customer(id: 'c1', name: 'John Mwangi', phone: '+256700123456'),
      Customer(id: 'c2', name: 'Sarah Nakato', phone: '+256772987654'),
    ];
  }

  void _load(Map<String, dynamic> j) {
    businessName = j['businessName'] ?? businessName;
    businessType = j['businessType'] ?? businessType;
    colorValue = j['colorValue'] ?? colorValue;
    taxRate = j['taxRate'] ?? taxRate;
    defaultReorder = j['defaultReorder'] ?? defaultReorder;
    dark = j['dark'] ?? false;
    products = (j['products'] as List? ?? [])
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    customers = (j['customers'] as List? ?? [])
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    sales = (j['sales'] as List? ?? [])
        .map((e) => Sale.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save() async {
    await _p?.setString(
      'data',
      jsonEncode({
        'businessName': businessName,
        'businessType': businessType,
        'colorValue': colorValue,
        'taxRate': taxRate,
        'defaultReorder': defaultReorder,
        'dark': dark,
        'products': products.map((e) => e.toJson()).toList(),
        'customers': customers.map((e) => e.toJson()).toList(),
        'sales': sales.map((e) => e.toJson()).toList(),
      }),
    );
  }

  /// Call after any change: saves locally and refreshes every screen.
  void changed() {
    _save();
    notifyListeners();
  }

  // ── cart / sale ──
  Product? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addToCart(Product p) {
    if ((cart[p.id] ?? 0) >= p.stock) return; // cannot sell more than in stock
    cart[p.id] = (cart[p.id] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(Product p) {
    final q = cart[p.id] ?? 0;
    if (q <= 1) {
      cart.remove(p.id);
    } else {
      cart[p.id] = q - 1;
    }
    notifyListeners();
  }

  void setCustomer(Customer? c) {
    customer = c;
    notifyListeners();
  }

  int get subtotal => cart.entries.fold(0, (s, e) {
        final p = byId(e.key);
        return s + (p == null ? 0 : p.price * e.value);
      });
  int get tax => (subtotal * taxRate / 100).round();
  int get total => subtotal + tax;

  Sale completeSale(String method) {
    final items = <SaleItem>[];
    for (final e in cart.entries) {
      final p = byId(e.key);
      if (p == null) continue;
      p.stock -= e.value; // inventory updates automatically
      items.add(SaleItem(p.name, p.price, e.value));
    }
    final sale = Sale(
      id: newId(),
      customer: customer?.name ?? 'Walk-in Customer',
      method: method,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      time: DateTime.now(),
      synced: !offline, // offline sales wait for sync
    );
    sales.insert(0, sale);
    cart.clear();
    customer = null;
    changed();
    return sale;
  }

  // ── offline sync (simulated) ──
  int get pendingCount => sales.where((s) => !s.synced).length;

  void syncPending() {
    // In a real app: POST each unsynced sale to your server/API here,
    // and only mark it synced when the server confirms.
    for (final s in sales) {
      s.synced = true;
    }
    changed();
  }

  // ── reporting helpers (real-time: computed from live data) ──
  int get todaySales {
    final n = DateTime.now();
    return sales
        .where((s) => s.time.year == n.year && s.time.month == n.month && s.time.day == n.day)
        .fold(0, (a, s) => a + s.total);
  }

  List<Sale> salesBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    return sales.where((s) => !s.time.isBefore(start) && s.time.isBefore(end)).toList();
  }

  Map<String, int> topProducts(List<Sale> list) {
    final m = <String, int>{};
    for (final s in list) {
      for (final i in s.items) {
        m[i.name] = (m[i.name] ?? 0) + i.qty;
      }
    }
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted.take(5)) e.key: e.value};
  }

  Map<String, int> byMethod(List<Sale> list) {
    final m = <String, int>{};
    for (final s in list) {
      m[s.method] = (m[s.method] ?? 0) + s.total;
    }
    return m;
  }

  // ── settings / management ──
  void updateSettings({String? name, String? type, int? color, int? tax, int? reorder, bool? isDark}) {
    businessName = name ?? businessName;
    businessType = type ?? businessType;
    colorValue = color ?? colorValue;
    taxRate = tax ?? taxRate;
    defaultReorder = reorder ?? defaultReorder;
    dark = isDark ?? dark;
    changed();
  }

  Future<void> clearAllData() async {
    products = [];
    customers = [];
    sales = [];
    cart.clear();
    await _p?.remove('data');
    await Auth.wipe();
    _seed();
    await _save();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final app = AppState(); // one shared instance used by all screens
