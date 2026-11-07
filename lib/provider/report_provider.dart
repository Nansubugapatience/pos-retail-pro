import 'package:flutter/foundation.dart';
import '../repository/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository repo;
  ReportProvider(this.repo);

  double todayTotal = 0;
  int todayCount = 0;
  List<MapEntry<String, int>> top = [];

  Future<void> load() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    todayTotal = await repo.totalBetween(start, end);
    todayCount = await repo.countBetween(start, end);
    top = await repo.topProducts();
    notifyListeners();
  }
}
