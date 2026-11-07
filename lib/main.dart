import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/app_db.dart';
import 'repository/auth_repository.dart';
import 'repository/product_repository.dart';
import 'repository/customer_repository.dart';
import 'repository/sale_repository.dart';
import 'repository/report_repository.dart';
import 'provider/auth_provider.dart';
import 'provider/product_provider.dart';
import 'provider/customer_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/sale_provider.dart';
import 'provider/report_provider.dart';
import 'app_state.dart';
import 'screens.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDb();
  runApp(MultiProvider(
    providers: [
      Provider.value(value: db),
      ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository(db))),
      ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository(db))),
      ChangeNotifierProvider(
          create: (_) => CustomerProvider(CustomerRepository(db))),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => SaleProvider(SaleRepository(db))),
      ChangeNotifierProvider(
          create: (_) => ReportProvider(ReportRepository(db))),
    ],
    child: const PosApp(), // use the name of your existing app widget
  ));
}


class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'POS Retail Pro',
          themeMode: app.dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Color(app.colorValue)),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Color(app.colorValue), brightness: Brightness.dark),
          ),
          home: SplashScreen(),
        ),
      );
}
