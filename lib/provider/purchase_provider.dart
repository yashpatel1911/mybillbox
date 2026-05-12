import 'package:flutter/material.dart';
import 'package:mybillbox/api_service/purchase_api_service.dart';
import '../model/purchase_details/purchase_dashboard_stats_model.dart';
import '../model/purchase_details/purchase_model.dart';
import '../model/purchase_details/purchase_payment_model.dart';

class PurchaseProvider extends ChangeNotifier {
  // ── Service ────────────────────────────────────
  final PurchaseApiService _api = PurchaseApiService();

  // ── Purchase State ─────────────────────────────
  List<PurchaseModel> purchases = [];
  List<PurchaseModel> todayPurchases = [];
  List<PurchaseModel> allPurchase = [];
  PurchaseModel? selectedPurchase;

  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;

  // ── Pagination State ───────────────────────────
  int _todayPage = 1;
  int _allPage = 1;
  bool _hasMoreToday = true;
  bool _hasMoreAll = true;

  bool get hasMoreToday => _hasMoreToday;

  bool get hasMoreAll => _hasMoreAll;

  // ── Active Filter State ────────────────────────
  String? _activeSearch;
  String? _activeStatus;
  String? _activeDateFrom;
  String? _activeDateTo;

  // ── Stats State ────────────────────────────────
  PurchaseDashboardStatsModel _stats = PurchaseDashboardStatsModel.empty();
  PurchaseDashboardStatsWrapper _statsWrapper =
      PurchaseDashboardStatsWrapper.empty();
  bool _statsLoading = false;

  PurchaseDashboardStatsModel get stats => _stats;

  PurchaseDashboardStatsWrapper get statsWrapper => _statsWrapper;

  bool get statsLoading => _statsLoading;

  // ── DASHBOARD STATS ────────────────────────────
  Future<void> fetchDashboardStats({
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    try {
      _statsLoading = true;
      notifyListeners();
      _statsWrapper = await _api.fetchPurchaseDashboardStats(
        paymentStatus: paymentStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: search,
      );
      _stats = _statsWrapper.allTime;
    } catch (e) {
      print('fetchDashboardStats error: $e');
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // ── FETCH PURCHASES page 1 ─────────────────────
  Future<void> fetchPurchases({
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    try {
      isLoading = true;
      _activeSearch = search;
      _activeStatus = paymentStatus;
      _activeDateFrom = dateFrom;
      _activeDateTo = dateTo;
      _todayPage = 1;
      _allPage = 1;
      _hasMoreToday = true;
      _hasMoreAll = true;
      notifyListeners();

      final data = await _api.fetchPurchasePage(
        page: 1,
        paymentStatus: paymentStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: search,
      );

      final todayMeta = data['today'] as Map<String, dynamic>;
      todayPurchases = (todayMeta['purchases'] as List)
          .map((e) => PurchaseModel.fromJson(e))
          .toList();
      _hasMoreToday = todayMeta['has_next'] as bool;

      final allMeta = data['all_time'] as Map<String, dynamic>;
      allPurchase = (allMeta['purchases'] as List)
          .map((e) => PurchaseModel.fromJson(e))
          .toList();
      _hasMoreAll = allMeta['has_next'] as bool;
      purchases = allPurchase;
    } catch (e) {
      errorMessage = e.toString();
      print('fetchPurchases error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── LOAD MORE Today ───────────────────────────
  Future<void> loadMoreToday() async {
    if (!_hasMoreToday || isLoadingMore) return;
    try {
      isLoadingMore = true;
      notifyListeners();
      final nextPage = _todayPage + 1;
      final data = await _api.fetchPurchasePage(
        page: nextPage,
        paymentStatus: _activeStatus,
        dateFrom: _activeDateFrom,
        dateTo: _activeDateTo,
        search: _activeSearch,
      );
      final todayMeta = data['today'] as Map<String, dynamic>;
      todayPurchases.addAll(
        (todayMeta['purchases'] as List).map((e) => PurchaseModel.fromJson(e)),
      );
      _hasMoreToday = todayMeta['has_next'] as bool;
      _todayPage = nextPage;
    } catch (e) {
      print('loadMoreToday error: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── LOAD MORE All Time ────────────────────────
  Future<void> loadMoreAll() async {
    if (!_hasMoreAll || isLoadingMore) return;
    try {
      isLoadingMore = true;
      notifyListeners();
      final nextPage = _allPage + 1;
      final data = await _api.fetchPurchasePage(
        page: nextPage,
        paymentStatus: _activeStatus,
        dateFrom: _activeDateFrom,
        dateTo: _activeDateTo,
        search: _activeSearch,
      );
      final allMeta = data['all_time'] as Map<String, dynamic>;
      allPurchase.addAll(
        (allMeta['purchases'] as List).map((e) => PurchaseModel.fromJson(e)),
      );
      purchases = allPurchase;
      _hasMoreAll = allMeta['has_next'] as bool;
      _allPage = nextPage;
    } catch (e) {
      print('loadMoreAll error: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── FETCH SINGLE PURCHASE ─────────────────────
  Future<PurchaseModel?> fetchPurchaseById(int purchaseId) async {
    try {
      selectedPurchase = await _api.fetchPurchaseById(purchaseId);
      notifyListeners();
      return selectedPurchase;
    } catch (e) {
      print('fetchPurchaseById error: $e');
      return null;
    }
  }

  // ── CREATE PURCHASE ───────────────────────────
  // payments = [{'method': 'cash', 'amount': 300.0}, {'method': 'online', 'amount': 200.0}]
  Future<Map<String, dynamic>> createPurchase({
    required String customerName,
    required String customerMobile,
    required String purchaseDate,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? discountType,
    double discountValue = 0,
    String paymentStatus = 'pending',
    List<Map<String, dynamic>> payments = const [],
    String? paymentDate,
  }) async {
    final res = await _api.createPurchase(
      customerName: customerName,
      customerMobile: customerMobile,
      purchaseDate: purchaseDate,
      items: items,
      notes: notes,
      discountType: discountType,
      discountValue: discountValue,
      paymentStatus: paymentStatus,
      payments: payments,
      paymentDate: paymentDate,
    );
    if (res['status'] == true) {
      final newPurchase = PurchaseModel.fromJson(res['data']);
      allPurchase.insert(0, newPurchase);
      todayPurchases.insert(0, newPurchase);
      purchases = allPurchase;
      notifyListeners();
    }
    return res;
  }

  // ── UPDATE PURCHASE ───────────────────────────
  Future<Map<String, dynamic>> updatePurchase({
    required int purchaseId,
    String? customerName,
    String? customerMobile,
    String? notes,
    String? purchaseDate,
    List<Map<String, dynamic>>? items,
    String? discountType,
    double? discountValue,
    String? paymentStatus,
    List<Map<String, dynamic>> payments = const [],
  }) async {
    final res = await _api.updatePurchase(
      purchaseId: purchaseId,
      customerName: customerName,
      customerMobile: customerMobile,
      notes: notes,
      purchaseDate: purchaseDate,
      items: items,
      discountType: discountType,
      discountValue: discountValue,
      paymentStatus: paymentStatus,
      payments: payments,
    );
    if (res['status'] == true) {
      final updated = PurchaseModel.fromJson(res['data']);
      final allIdx = allPurchase.indexWhere((e) => e.purchaseId == purchaseId);
      if (allIdx != -1) allPurchase[allIdx] = updated;
      final todayIdx = todayPurchases.indexWhere(
        (e) => e.purchaseId == purchaseId,
      );
      if (todayIdx != -1) todayPurchases[todayIdx] = updated;
      purchases = allPurchase;
      selectedPurchase = updated;

      // ── Re-fetch stats so dashboard reflects updated amounts ──
      await fetchDashboardStats(
        paymentStatus: _activeStatus,
        dateFrom: _activeDateFrom,
        dateTo: _activeDateTo,
        search: _activeSearch,
      );

      notifyListeners();
    }
    return res;
  }

  // ── CANCEL PURCHASE ───────────────────────────
  Future<Map<String, dynamic>> cancelPurchase(int purchaseId) async {
    final res = await _api.cancelPurchase(purchaseId);
    if (res['status'] == true) {
      allPurchase.removeWhere((e) => e.purchaseId == purchaseId);
      todayPurchases.removeWhere((e) => e.purchaseId == purchaseId);
      purchases = allPurchase;
      notifyListeners();
    }
    return res;
  }

  // ── ADD PAYMENT ───────────────────────────────
  // payments = [{'method': 'cash', 'amount': 300.0}, {'method': 'online', 'amount': 200.0}]
  Future<Map<String, dynamic>> addPayment({
    required int purchaseId,
    required List<Map<String, dynamic>> payments,
    String? paymentDate,
    String? note,
  }) async {
    final res = await _api.addPayment(
      purchaseId: purchaseId,
      payments: payments,
      paymentDate: paymentDate,
      note: note,
    );
    if (res['status'] == true) {
      await fetchPurchaseById(purchaseId);
    }
    return res;
  }

  // ── FETCH PAYMENT HISTORY ─────────────────────
  Future<PurchasePaymentSummaryModel?> fetchPayments(int purchaseId) async {
    try {
      return await _api.fetchPayments(purchaseId);
    } catch (e) {
      print('fetchPayments error: $e');
      return null;
    }
  }

  // ── CLEAR STATE ───────────────────────────────
  void clearSelected() {
    selectedPurchase = null;
    notifyListeners();
  }
}
