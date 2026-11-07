import 'dart:async';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

// ───────────────────────── SHARED HELPERS ─────────────────────────
Widget _field(TextEditingController c, String label, {bool number = false, bool optional = false}) =>
    TextFormField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return optional ? null : 'Required';
        if (number && int.tryParse(t) == null) return 'Numbers only';
        return null;
      },
    );

String _time(DateTime t) =>
    '${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ───────────────────────── 1. SPLASH ─────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Icon(Icons.shopping_cart, size: 90, color: c),
          const SizedBox(height: 12),
          const Text('POS Retail Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Manage your business anytime, anywhere'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Get Started'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}

// ───────────────────────── 2. LOGIN / SIGN UP ─────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true, _signUp = false, _busy = false;
  int _fails = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    Auth.hasAccount().then((has) {
      if (mounted) setState(() => _signUp = !has); // first run -> create account
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      _msg('Too many attempts. Try again in a moment.');
      return;
    }
    setState(() => _busy = true);
    if (_signUp) {
      await Auth.register(_email.text, _pass.text);
      _enter();
    } else {
      final ok = await Auth.login(_email.text, _pass.text);
      if (ok) {
        _enter();
      } else {
        _fails++;
        if (_fails >= 5) {
          _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
          _fails = 0;
          _msg('Locked for 30 seconds after 5 failed attempts.');
        } else {
          _msg('Wrong email or password.');
        }
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  void _enter() {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _key,
              child: ListView(children: [
                const SizedBox(height: 24),
                Text(_signUp ? 'Create Account' : 'Login',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(_signUp ? 'Set up your owner account' : 'Sign in to your account'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder()),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) {
                    final t = v ?? '';
                    if (!_signUp) return t.isEmpty ? 'Required' : null;
                    if (t.length < 8 || !RegExp(r'\d').hasMatch(t)) {
                      return 'Min 8 characters and 1 number';
                    }
                    return null;
                  },
                ),
                if (_signUp) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder()),
                    validator: (v) => v == _pass.text ? null : 'Passwords do not match',
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_signUp ? 'Sign Up' : 'Login'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _signUp = !_signUp),
                  child: Text(_signUp ? 'Already have an account? Login' : "Don't have an account? Sign Up"),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── HOME SHELL (bottom nav + offline banner) ─────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  void go(int i) => setState(() => _i = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onTab: go),
      const ProductsScreen(),
      const InventoryScreen(),
      const CustomersScreen(),
      const SettingsScreen(),
    ];
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            if (app.offline)
              Material(
                color: Colors.orange.shade700,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const OfflineScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Working offline  •  ${app.pendingCount} sale(s) waiting to sync',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            Expanded(child: pages[_i]),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Sales'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Inventory'),
            NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 3. DASHBOARD ─────────────────────────
class DashboardScreen extends StatelessWidget {
  final void Function(int) onTab;
  const DashboardScreen({super.key, required this.onTab});

  Widget _tile(IconData i, String t, VoidCallback f) => Card(
        child: InkWell(
          onTap: f,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 30),
            const SizedBox(height: 6),
            Text(t),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('$greet,\n${app.businessName}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Today's Sales", style: TextStyle(color: Colors.white70)),
          Text(money(app.todaySales),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2,
        children: [
          _tile(Icons.shopping_cart, 'New Sale', () => onTab(1)),
          _tile(Icons.inventory_2, 'Inventory', () => onTab(2)),
          _tile(Icons.people, 'Customers', () => onTab(3)),
          _tile(Icons.bar_chart, 'Reports',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
        ],
      ),
      const SizedBox(height: 8),
      const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
      if (app.sales.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('No sales yet.')),
      for (final s in app.sales.take(5))
        ListTile(
          leading: Icon(s.synced ? Icons.cloud_done : Icons.cloud_off, color: s.synced ? Colors.green : Colors.orange),
          title: Text(s.method),
          subtitle: Text('${s.customer} • ${_time(s.time)}'),
          trailing: Text(money(s.total)),
        ),
    ]);
  }
}

// ───────────────────────── 4. PRODUCT SELECTION ─────────────────────────
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _q = '', _cat = 'All';
  Timer? _debounce; // wait until typing pauses (saves CPU/battery)

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final cats = ['All', ...{...app.products.map((p) => p.category)}];
          final list = app.products
              .where((p) =>
                  (_cat == 'All' || p.category == _cat) &&
                  p.name.toLowerCase().contains(_q.toLowerCase()))
              .toList();
          return Scaffold(
            appBar: AppBar(title: const Text('Products')),
            body: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _q = v));
                  },
                  decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                            label: Text(c), selected: _cat == c, onSelected: (_) => setState(() => _cat = c)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final inCart = app.cart[p.id] ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.local_mall),
                      title: Text(p.name),
                      subtitle: Text('${money(p.price)}\nStock: ${p.stock}'),
                      isThreeLine: true,
                      trailing: p.stock == 0
                          ? const Text('Out of stock', style: TextStyle(color: Colors.red))
                          : Badge(
                              isLabelVisible: inCart > 0,
                              label: Text('$inCart'),
                              child: IconButton.filled(
                                  icon: const Icon(Icons.add), onPressed: () => app.addToCart(p)),
                            ),
                    );
                  },
                ),
              ),
            ]),
            floatingActionButton: app.cart.isEmpty
                ? null
                : FloatingActionButton.extended(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: Text('Cart (${app.cart.length})'),
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  ),
          );
        },
      );
}

// ───────────────────────── 5. CHECKOUT ─────────────────────────
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  Widget _row(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: s), Text(b, style: s)]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('New Sale')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(app.customer?.name ?? 'Walk-in Customer'),
                trailing: TextButton(
                  child: const Text('Change'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (sheet) => ListView(children: [
                      ListTile(
                        title: const Text('Walk-in Customer'),
                        onTap: () {
                          app.setCustomer(null);
                          Navigator.pop(sheet);
                        },
                      ),
                      for (final c in app.customers)
                        ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          onTap: () {
                            app.setCustomer(c);
                            Navigator.pop(sheet);
                          },
                        ),
                    ]),
                  ),
                ),
              ),
            ),
            for (final e in app.cart.entries)
              if (app.byId(e.key) != null)
                ListTile(
                  title: Text(app.byId(e.key)!.name),
                  subtitle: Text(money(app.byId(e.key)!.price)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          app.removeFromCart(app.byId(e.key)!);
                          if (app.cart.isEmpty) Navigator.pop(context);
                        }),
                    Text('${e.value}'),
                    IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => app.addToCart(app.byId(e.key)!)),
                  ]),
                ),
            const Divider(),
            _row('Subtotal', money(app.subtotal)),
            _row('Tax (${app.taxRate}%)', money(app.tax)),
            _row('Total', money(app.total), bold: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: app.cart.isEmpty
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
              child: const Text('Complete Sale'),
            ),
          ]),
        ),
      );
}

// ───────────────────────── 6. PAYMENT METHODS ─────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _methods = {
    'Cash': Icons.payments,
    'Credit / Debit Card': Icons.credit_card,
    'Mobile Money': Icons.phone_android,
    'Bank Transfer': Icons.account_balance,
  };
  String _m = 'Cash';
  bool _busy = false;
  final _tendered = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _tendered.dispose();
    _phone.dispose();
    super.dispose();
  }

  int get _change => (int.tryParse(_tendered.text) ?? 0) - app.total;

  Future<void> _pay() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_m == 'Cash' && _change < 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Cash received is less than the total.')));
      return;
    }
    if (_m == 'Mobile Money' && !RegExp(r'^\+?\d{9,13}$').hasMatch(_phone.text.trim())) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid mobile money number.')));
      return;
    }
    setState(() => _busy = true);
    // Simulated processing. Real app: call the payment gateway
    // (MTN/Airtel MoMo, Flutterwave, Stripe...) and wait for confirmation.
    await Future.delayed(const Duration(seconds: 1));
    final sale = app.completeSale(_m);
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final i in sale.items) Text('${i.qty} x ${i.name}  ${money(i.price * i.qty)}'),
          const Divider(),
          Text('Tax: ${money(sale.tax)}'),
          Text('Total: ${money(sale.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Method: ${sale.method}'),
          if (_m == 'Cash') Text('Change: ${money(_change)}'),
          if (!sale.synced) const Text('Saved offline – will sync later.', style: TextStyle(color: Colors.orange)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Done'))],
      ),
    );
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Center(child: Text('Total Amount')),
          Center(child: Text(money(app.total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          for (final e in _methods.entries)
            Card(
              child: ListTile(
                leading: Icon(e.value),
                title: Text(e.key),
                trailing: Icon(_m == e.key ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                onTap: () => setState(() => _m = e.key),
              ),
            ),
          const SizedBox(height: 8),
          if (_m == 'Cash') ...[
            TextField(
              controller: _tendered,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Cash received', border: OutlineInputBorder()),
            ),
            if (_tendered.text.isNotEmpty && _change >= 0)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('Change: ${money(_change)}')),
          ],
          if (_m == 'Mobile Money')
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Customer phone (MTN/Airtel)', border: OutlineInputBorder()),
            ),
          if (_m == 'Credit / Debit Card')
            const Text('Card is charged on the card terminal/gateway. Card numbers are never stored in this app.',
                style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _pay,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Pay Now'),
          ),
        ]),
      );
}

// ───────────────────────── 7. INVENTORY ─────────────────────────
Future<void> productDialog(BuildContext ctx, {Product? p}) async {
  final n = TextEditingController(text: p?.name);
  final c = TextEditingController(text: p?.category ?? 'Groceries');
  final pr = TextEditingController(text: p?.price.toString());
  final st = TextEditingController(text: p?.stock.toString());
  final re = TextEditingController(text: (p?.reorder ?? app.defaultReorder).toString());
  final key = GlobalKey<FormState>();
  await showDialog(
    context: ctx,
    builder: (d) => AlertDialog(
      title: Text(p == null ? 'Add Product' : 'Edit Product'),
      content: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(n, 'Name'),
            _field(c, 'Category'),
            _field(pr, 'Price', number: true),
            _field(st, 'Stock', number: true),
            _field(re, 'Reorder level', number: true),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!key.currentState!.validate()) return;
            if (p == null) {
              app.products.add(Product(
                id: newId(),
                name: n.text.trim(),
                category: c.text.trim(),
                price: int.parse(pr.text.trim()),
                stock: int.parse(st.text.trim()),
                reorder: int.parse(re.text.trim()),
              ));
            } else {
              p.name = n.text.trim();
              p.category = c.text.trim();
              p.price = int.parse(pr.text.trim());
              p.stock = int.parse(st.text.trim());
              p.reorder = int.parse(re.text.trim());
            }
            app.changed();
            Navigator.pop(d);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _low = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final list = app.products.where((p) => !_low || p.stock <= p.reorder).toList();
          return Scaffold(
            appBar: AppBar(title: const Text('Inventory')),
            body: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  ChoiceChip(label: const Text('Stock'), selected: !_low, onSelected: (_) => setState(() => _low = false)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Low Stock'), selected: _low, onSelected: (_) => setState(() => _low = true)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final low = p.stock <= p.reorder;
                    return ListTile(
                      leading: Icon(low ? Icons.warning_amber : Icons.inventory_2, color: low ? Colors.orange : null),
                      title: Text(p.name),
                      subtitle: Text('${p.category} • Stock: ${p.stock}  Reorder: ${p.reorder}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await productDialog(context, p: p);
                          } else {
                            app.products.remove(p);
                            app.cart.remove(p.id);
                            app.changed();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit / Restock')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ]),
            floatingActionButton: FloatingActionButton(
                onPressed: () => productDialog(context), child: const Icon(Icons.add)),
          );
        },
      );
}

// ───────────────────────── 8. CUSTOMERS ─────────────────────────
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  Future<void> _dialog(BuildContext ctx, {Customer? c}) async {
    final n = TextEditingController(text: c?.name);
    final p = TextEditingController(text: c?.phone);
    final key = GlobalKey<FormState>();
    await showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(c == null ? 'Add Customer' : 'Edit Customer'),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(n, 'Name'),
            TextFormField(
              controller: p,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) => RegExp(r'^\+?\d{9,13}$').hasMatch(v?.trim() ?? '') ? null : 'Invalid phone',
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              if (c == null) {
                app.customers.add(Customer(id: newId(), name: n.text.trim(), phone: p.text.trim()));
              } else {
                c.name = n.text.trim();
                c.phone = p.text.trim();
              }
              app.changed();
              Navigator.pop(d);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Customers')),
          body: ListView.builder(
            itemCount: app.customers.length,
            itemBuilder: (_, i) {
              final c = app.customers[i];
              final mine = app.sales.where((s) => s.customer == c.name);
              final spent = mine.fold(0, (a, s) => a + s.total);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c.name),
                subtitle: Text('${c.phone}\n${mine.length} purchase(s) • ${money(spent)}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      _dialog(context, c: c);
                    } else {
                      app.customers.remove(c);
                      app.changed();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _dialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer')),
        ),
      );
}

// ───────────────────────── 9. REPORTS & ANALYTICS ─────────────────────────
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 7; // 7, 30 or 0 = custom
  DateTimeRange? _range;

  DateTimeRange get _active {
    if (_days == 0 && _range != null) return _range!;
    final now = DateTime.now();
    return DateTimeRange(start: now.subtract(Duration(days: _days - 1)), end: now);
  }

  Future<void> _pick() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (r != null) {
      setState(() {
      _days = 0;
      _range = r;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ListenableBuilder(
        listenable: app, // updates instantly when a sale is completed
        builder: (_, _) {
          final r = _active;
          final list = app.salesBetween(r.start, r.end);
          final total = list.fold(0, (a, s) => a + s.total);

          // Daily totals (limit to the last 31 days so bars stay readable)
          final dayCount = (r.end.difference(r.start).inDays + 1).clamp(1, 31);
          final first = DateTime(r.end.year, r.end.month, r.end.day).subtract(Duration(days: dayCount - 1));
          final daily = List<int>.generate(dayCount, (i) {
            final d = first.add(Duration(days: i));
            return list
                .where((s) => s.time.year == d.year && s.time.month == d.month && s.time.day == d.day)
                .fold(0, (a, s) => a + s.total);
          });
          final mx = daily.fold(1, (a, b) => b > a ? b : a);
          final top = app.topProducts(list);
          final methods = app.byMethod(list);

          return ListView(padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('7 Days'), selected: _days == 7, onSelected: (_) => setState(() => _days = 7)),
              ChoiceChip(label: const Text('30 Days'), selected: _days == 30, onSelected: (_) => setState(() => _days = 30)),
              ChoiceChip(label: const Text('Custom'), selected: _days == 0, onSelected: (_) => _pick()),
            ]),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Total Sales'),
                subtitle: Text(money(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                trailing: Text('${list.length} sales'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final v in daily)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4 + 140 * v / mx,
                        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${first.day}/${first.month}', style: const TextStyle(fontSize: 11)),
              Text('${r.end.day}/${r.end.month}', style: const TextStyle(fontSize: 11)),
            ]),
            const SizedBox(height: 16),
            const Text('Top Products (units sold)', style: TextStyle(fontWeight: FontWeight.bold)),
            if (top.isEmpty) const Text('No sales in this period.'),
            for (final e in top.entries) ListTile(dense: true, title: Text(e.key), trailing: Text('${e.value}')),
            const SizedBox(height: 8),
            const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in methods.entries)
              ListTile(dense: true, title: Text(e.key), trailing: Text(money(e.value))),
          ]);
        },
      ),
    );
  }
}

// ───────────────────────── 10. SETTINGS ─────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final o = TextEditingController(), n = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: o, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
          TextField(controller: n, obscureText: true, decoration: const InputDecoration(labelText: 'New password (8+ chars, 1 number)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (n.text.length < 8 || !RegExp(r'\d').hasMatch(n.text)) {
                messenger.showSnackBar(const SnackBar(content: Text('Weak new password.')));
                return;
              }
              final ok = await Auth.changePassword(o.text, n.text);
              if (d.mounted) Navigator.pop(d);
              messenger.showSnackBar(SnackBar(content: Text(ok ? 'Password changed.' : 'Current password is wrong.')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text('This deletes products, customers, sales and your account from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Erase')),
        ],
      ),
    );
    if (ok == true) {
      await app.clearAllData();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    Widget item(IconData i, String t, VoidCallback f) =>
        ListTile(leading: Icon(i), title: Text(t), trailing: const Icon(Icons.chevron_right), onTap: f);
    return ListView(children: [
      FutureBuilder<String?>(
        future: Auth.email(),
        builder: (_, s) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('Business Owner'),
          subtitle: Text(s.data ?? ''),
        ),
      ),
      item(Icons.store, 'Business Profile', () => open(const BusinessProfileScreen())),
      item(Icons.tune, 'Tax, Inventory & Appearance', () => open(const PreferencesScreen())),
      item(Icons.cloud_sync, 'Offline & Sync', () => open(const OfflineScreen())),
      item(Icons.lock_reset, 'Change Password', () => _changePassword(context)),
      item(Icons.delete_forever, 'Erase All Data', () => _clear(context)),
      item(Icons.logout, 'Log Out', () {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
      }),
      item(Icons.info_outline, 'About', () => showAboutDialog(
            context: context,
            applicationName: 'POS Retail Pro',
            applicationVersion: '1.0.0',
          )),
    ]);
  }
}

// Tax rate, default reorder level, dark mode
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final _tax = TextEditingController(text: app.taxRate.toString());
  late final _reorder = TextEditingController(text: app.defaultReorder.toString());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Preferences')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _tax,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tax rate (%)', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(
              controller: _reorder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default reorder level', border: OutlineInputBorder())),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: app.dark,
            onChanged: (v) {
              app.updateSettings(isDark: v);
              setState(() {});
            },
          ),
          FilledButton(
            onPressed: () {
              final t = int.tryParse(_tax.text), r = int.tryParse(_reorder.text);
              if (t == null || t < 0 || t > 100 || r == null || r < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check the values.')));
                return;
              }
              app.updateSettings(tax: t, reorder: r);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ]),
      );
}

// ───────────────────────── 11. OFFLINE MODE ─────────────────────────
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Offline & Sync')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(app.offline ? Icons.wifi_off : Icons.wifi, size: 80, color: Colors.grey),
                const SizedBox(height: 12),
                Text(app.offline ? "You're Offline" : "You're Online",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  app.offline
                      ? 'No internet connection detected. You can still process sales, view saved data and manage inventory.'
                      : 'All features available.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Chip(label: Text('${app.pendingCount} sale(s) waiting to sync')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync now'),
                  onPressed: app.offline || app.pendingCount == 0 ? null : app.syncPending,
                ),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── 12. CUSTOMIZATION / BUSINESS PROFILE ─────────────────────────
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});
  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late final _name = TextEditingController(text: app.businessName);
  late String _type = app.businessType;
  late int _color = app.colorValue;
  static const _types = ['Retail Store', 'Restaurant', 'Pharmacy', 'Salon', 'Supermarket'];
  static const _colors = [0xFF7B1FA2, 0xFF1E5EFF, 0xFF2E7D32, 0xFFF9A825, 0xFFEF6C00];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Business Type', border: OutlineInputBorder()),
            items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 14),
          const Text('Theme Color'),
          Row(children: [
            for (final c in _colors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(width: 3, color: _color == c ? Colors.black : Colors.transparent),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              app.updateSettings(name: _name.text.trim(), type: _type, color: _color);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ]),
      );
}
