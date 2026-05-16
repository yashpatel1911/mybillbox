import 'package:flutter/foundation.dart';

import '../../api_service/api_service.dart';
import '../../model/reports/expenses_report_model.dart';
import '../../model/reports/report_summary_model.dart';
import '../../model/reports/sales_report_model.dart';
import '../../screens/reports/report_period.dart';

class ReportsProvider extends ChangeNotifier {
  final ServiceDB _service;

  ReportsProvider({ServiceDB? service}) : _service = service ?? ServiceDB() {
    _period = ReportPeriod.thisMonth();
  }

  // ── Shared state ─────────────────────────────────────────
  late ReportPeriod _period;

  ReportPeriod get period => _period;

  // ── Summary (Overview tab) ───────────────────────────────
  bool _summaryLoading = false;

  bool get isLoading => _summaryLoading;

  bool get isSummaryLoading => _summaryLoading;

  String? _summaryError;

  String? get error => _summaryError;

  String? get summaryError => _summaryError;

  final Map<String, ReportSummary> _summaryCache = {};
  ReportSummary _summary = ReportSummary.empty();

  ReportSummary get summary => _summary;

  // ── Sales tab ────────────────────────────────────────────
  bool _salesLoading = false;

  bool get isSalesLoading => _salesLoading;

  String? _salesError;

  String? get salesError => _salesError;

  final Map<String, SalesReport> _salesCache = {};
  SalesReport _salesReport = SalesReport.empty();

  SalesReport get salesReport => _salesReport;

  bool _salesEverFetched = false;

  // ── Expenses tab ─────────────────────────────────────────
  bool _expensesLoading = false;

  bool get isExpensesLoading => _expensesLoading;

  String? _expensesError;

  String? get expensesError => _expensesError;

  final Map<String, ExpensesReport> _expensesCache = {};
  ExpensesReport _expensesReport = ExpensesReport.empty();

  ExpensesReport get expensesReport => _expensesReport;

  bool _expensesEverFetched = false;

  String _cacheKey(ReportPeriod p) => '${p.fromApi}_${p.toApi}';

  // ── Change period — refresh all tabs that were already viewed ──
  Future<void> setPeriod(ReportPeriod next) async {
    _period = next;
    final key = _cacheKey(next);

    // Summary always loads
    if (_summaryCache.containsKey(key)) {
      _summary = _summaryCache[key]!;
      _summaryError = null;
      notifyListeners();
    } else {
      await fetchSummary();
    }

    // Refresh other tabs only if they were viewed before
    if (_salesEverFetched) {
      if (_salesCache.containsKey(key)) {
        _salesReport = _salesCache[key]!;
        _salesError = null;
        notifyListeners();
      } else {
        await fetchSales();
      }
    }

    if (_expensesEverFetched) {
      if (_expensesCache.containsKey(key)) {
        _expensesReport = _expensesCache[key]!;
        _expensesError = null;
        notifyListeners();
      } else {
        await fetchExpenses();
      }
    }
  }

  // ── Refresh everything ───────────────────────────────────
  Future<void> refresh() async {
    final key = _cacheKey(_period);
    _summaryCache.remove(key);
    _salesCache.remove(key);
    _expensesCache.remove(key);

    await fetchSummary();
    if (_salesEverFetched) await fetchSales();
    if (_expensesEverFetched) await fetchExpenses();
  }

  // ── Fetch summary ─────────────────────────────────────────
  Future<void> fetchSummary() async {
    _summaryLoading = true;
    _summaryError = null;
    notifyListeners();

    try {
      final s = await _service.fetchReportsSummary(
        fromDate: _period.fromApi,
        toDate: _period.toApi,
      );
      _summary = s;
      _summaryCache[_cacheKey(_period)] = s;
    } catch (e) {
      _summaryError = e.toString().replaceFirst('Exception: ', '');
      _summary = ReportSummary.empty();
    } finally {
      _summaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetch() => fetchSummary();

  // ── Fetch sales ──────────────────────────────────────────
  Future<void> fetchSales() async {
    _salesEverFetched = true;
    final key = _cacheKey(_period);

    if (_salesCache.containsKey(key)) {
      _salesReport = _salesCache[key]!;
      _salesError = null;
      notifyListeners();
      return;
    }

    _salesLoading = true;
    _salesError = null;
    notifyListeners();

    try {
      final r = await _service.fetchSalesReport(
        fromDate: _period.fromApi,
        toDate: _period.toApi,
      );
      _salesReport = r;
      _salesCache[key] = r;
    } catch (e) {
      _salesError = e.toString().replaceFirst('Exception: ', '');
      _salesReport = SalesReport.empty();
    } finally {
      _salesLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch expenses ───────────────────────────────────────
  Future<void> fetchExpenses() async {
    _expensesEverFetched = true;
    final key = _cacheKey(_period);

    if (_expensesCache.containsKey(key)) {
      _expensesReport = _expensesCache[key]!;
      _expensesError = null;
      notifyListeners();
      return;
    }

    _expensesLoading = true;
    _expensesError = null;
    notifyListeners();

    try {
      final r = await _service.fetchExpensesReport(
        fromDate: _period.fromApi,
        toDate: _period.toApi,
      );
      _expensesReport = r;
      _expensesCache[key] = r;
    } catch (e) {
      _expensesError = e.toString().replaceFirst('Exception: ', '');
      _expensesReport = ExpensesReport.empty();
    } finally {
      _expensesLoading = false;
      notifyListeners();
    }
  }
}
