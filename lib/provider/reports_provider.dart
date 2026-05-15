import 'package:flutter/foundation.dart';

import '../../model/report_summary_model.dart';
import '../api_service/api_service.dart';
import '../screens/reports/report_period.dart';

class ReportsProvider extends ChangeNotifier {
  // ── Service (injected for testability; defaults to a new instance) ──
  final ServiceDB _service;

  ReportsProvider({ServiceDB? service}) : _service = service ?? ServiceDB() {
    _period = ReportPeriod.thisMonth();
  }

  // ── State ────────────────────────────────────────────────
  late ReportPeriod _period;

  ReportPeriod get period => _period;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  // Cache per period so quickly switching tabs doesn't re-fetch.
  final Map<String, ReportSummary> _cache = {};

  ReportSummary _summary = ReportSummary.empty();

  ReportSummary get summary => _summary;

  String _cacheKey(ReportPeriod p) => '${p.fromApi}_${p.toApi}';

  // ── Change period (triggers fetch unless cached) ─────────
  Future<void> setPeriod(ReportPeriod next) async {
    _period = next;
    final key = _cacheKey(next);

    if (_cache.containsKey(key)) {
      _summary = _cache[key]!;
      _error = null;
      notifyListeners();
      return;
    }

    await fetch();
  }

  // ── Force refresh (pull-to-refresh) ──────────────────────
  Future<void> refresh() async {
    _cache.remove(_cacheKey(_period));
    await fetch();
  }

  // ── Fetch from API via ServiceDB ─────────────────────────
  Future<void> fetch() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final summary = await _service.fetchReportsSummary(
        fromDate: _period.fromApi,
        toDate: _period.toApi,
      );

      _summary = summary;
      _cache[_cacheKey(_period)] = summary;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _summary = ReportSummary.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
