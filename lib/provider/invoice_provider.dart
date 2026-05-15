import 'package:flutter/material.dart';
import '../model/invoice_details/dashboard_stats_model.dart';
import '../model/invoice_details/invoice_model.dart';
import '../model/invoice_details/invoice_payment_model.dart';
import '../model/invoice_details/customer_model.dart';
import '../api_service/invoice_api_service.dart';

class InvoiceProvider extends ChangeNotifier {
  // ── Service ────────────────────────────────────
  final InvoiceApiService _api = InvoiceApiService();

  // ── Invoice State ──────────────────────────────
  List<InvoiceModel> invoices = [];
  List<InvoiceModel> todayInvoices = [];
  List<InvoiceModel> allInvoices = [];
  InvoiceModel? selectedInvoice;

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
  DashboardStatsModel _stats = DashboardStatsModel.empty();
  DashboardStatsWrapper _statsWrapper = DashboardStatsWrapper.empty();
  bool _statsLoading = false;

  DashboardStatsModel get stats => _stats;

  DashboardStatsWrapper get statsWrapper => _statsWrapper;

  bool get statsLoading => _statsLoading;

  // ── Customer Lookup State ──────────────────────
  CustomerModel? _lookedUpCustomer;
  bool _customerLookupLoading = false;

  CustomerModel? get lookedUpCustomer => _lookedUpCustomer;

  bool get customerLookupLoading => _customerLookupLoading;

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
      _statsWrapper = await _api.fetchDashboardStats(
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

  // ── FETCH INVOICES page 1 ─────────────────────
  Future<void> fetchInvoices({
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

      final data = await _api.fetchInvoicePage(
        page: 1,
        paymentStatus: paymentStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: search,
      );

      final todayMeta = data['today'] as Map<String, dynamic>;
      todayInvoices = (todayMeta['invoices'] as List)
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
      _hasMoreToday = todayMeta['has_next'] as bool;

      final allMeta = data['all_time'] as Map<String, dynamic>;
      allInvoices = (allMeta['invoices'] as List)
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
      _hasMoreAll = allMeta['has_next'] as bool;
      invoices = allInvoices;
    } catch (e) {
      errorMessage = e.toString();
      print('fetchInvoices error: $e');
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
      final data = await _api.fetchInvoicePage(
        page: nextPage,
        paymentStatus: _activeStatus,
        dateFrom: _activeDateFrom,
        dateTo: _activeDateTo,
        search: _activeSearch,
      );
      final todayMeta = data['today'] as Map<String, dynamic>;
      todayInvoices.addAll(
        (todayMeta['invoices'] as List).map((e) => InvoiceModel.fromJson(e)),
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
      final data = await _api.fetchInvoicePage(
        page: nextPage,
        paymentStatus: _activeStatus,
        dateFrom: _activeDateFrom,
        dateTo: _activeDateTo,
        search: _activeSearch,
      );
      final allMeta = data['all_time'] as Map<String, dynamic>;
      allInvoices.addAll(
        (allMeta['invoices'] as List).map((e) => InvoiceModel.fromJson(e)),
      );
      invoices = allInvoices;
      _hasMoreAll = allMeta['has_next'] as bool;
      _allPage = nextPage;
    } catch (e) {
      print('loadMoreAll error: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── FETCH SINGLE INVOICE ──────────────────────
  Future<InvoiceModel?> fetchInvoiceById(int invoiceId) async {
    try {
      selectedInvoice = await _api.fetchInvoiceById(invoiceId);
      notifyListeners();
      return selectedInvoice;
    } catch (e) {
      print('fetchInvoiceById error: $e');
      return null;
    }
  }

  // ── CREATE INVOICE ────────────────────────────
  // payments = [{'method': 'cash', 'amount': 300.0}, {'method': 'online', 'amount': 200.0}]
  // creditToApply = amount to deduct from customer's existing credit balance.
  Future<Map<String, dynamic>> createInvoice({
    required String customerName,
    required String customerMobile,
    required String invoiceDate,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? discountType,
    double discountValue = 0,
    double creditToApply = 0,
    String paymentStatus = 'pending',
    List<Map<String, dynamic>> payments = const [],
    String? paymentDate,
  }) async {
    final res = await _api.createInvoice(
      customerName: customerName,
      customerMobile: customerMobile,
      invoiceDate: invoiceDate,
      items: items,
      notes: notes,
      discountType: discountType,
      discountValue: discountValue,
      creditToApply: creditToApply,
      paymentStatus: paymentStatus,
      payments: payments,
      paymentDate: paymentDate,
    );
    if (res['status'] == true) {
      final newInvoice = InvoiceModel.fromJson(res['data']);
      allInvoices.insert(0, newInvoice);
      todayInvoices.insert(0, newInvoice);
      invoices = allInvoices;

      // Clear cached customer lookup — balance just changed if credit was used
      _lookedUpCustomer = null;

      // Refresh stats so dashboard reflects the new invoice + credit usage
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

  // ── UPDATE INVOICE ────────────────────────────
  Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    String? customerName,
    String? customerMobile,
    String? notes,
    String? invoiceDate,
    List<Map<String, dynamic>>? items,
    String? discountType,
    double? discountValue,
    String? paymentStatus,
    List<Map<String, dynamic>> payments = const [],
  }) async {
    final res = await _api.updateInvoice(
      invoiceId: invoiceId,
      customerName: customerName,
      customerMobile: customerMobile,
      notes: notes,
      invoiceDate: invoiceDate,
      items: items,
      discountType: discountType,
      discountValue: discountValue,
      paymentStatus: paymentStatus,
      payments: payments,
    );
    if (res['status'] == true) {
      final updated = InvoiceModel.fromJson(res['data']);
      final allIdx = allInvoices.indexWhere((e) => e.invoiceId == invoiceId);
      if (allIdx != -1) allInvoices[allIdx] = updated;
      final todayIdx = todayInvoices.indexWhere(
        (e) => e.invoiceId == invoiceId,
      );
      if (todayIdx != -1) todayInvoices[todayIdx] = updated;
      invoices = allInvoices;
      selectedInvoice = updated;

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

  // ── CANCEL INVOICE ────────────────────────────
  Future<Map<String, dynamic>> cancelInvoice(int invoiceId) async {
    final res = await _api.cancelInvoice(invoiceId);
    if (res['status'] == true) {
      allInvoices.removeWhere((e) => e.invoiceId == invoiceId);
      todayInvoices.removeWhere((e) => e.invoiceId == invoiceId);
      invoices = allInvoices;
      notifyListeners();
    }
    return res;
  }

  // ── ADD PAYMENT ───────────────────────────────
  // payments = [{'method': 'cash', 'amount': 300.0}, {'method': 'online', 'amount': 200.0}]
  Future<Map<String, dynamic>> addPayment({
    required int invoiceId,
    required List<Map<String, dynamic>> payments,
    String? paymentDate,
    String? note,
  }) async {
    final res = await _api.addPayment(
      invoiceId: invoiceId,
      payments: payments,
      paymentDate: paymentDate,
      note: note,
    );
    if (res['status'] == true) {
      await fetchInvoiceById(invoiceId);
    }
    return res;
  }

  // ── FETCH PAYMENT HISTORY ─────────────────────
  Future<InvoicePaymentSummaryModel?> fetchPayments(int invoiceId) async {
    try {
      return await _api.fetchPayments(invoiceId);
    } catch (e) {
      print('fetchPayments error: $e');
      return null;
    }
  }

  // ── RESOLVE OVERPAYMENT ───────────────────────
  // action: 'refund' (cash returned offline) or 'credit' (added to customer credit_balance)
  Future<Map<String, dynamic>> resolveOverpayment({
    required int invoiceId,
    required String action,
  }) async {
    final res = await _api.resolveOverpayment(
      invoiceId: invoiceId,
      action: action,
    );
    if (res['status'] == true) {
      final updated = InvoiceModel.fromJson(res['data']);

      // Sync local lists so any banner/badge disappears immediately
      final allIdx = allInvoices.indexWhere((e) => e.invoiceId == invoiceId);
      if (allIdx != -1) allInvoices[allIdx] = updated;
      final todayIdx = todayInvoices.indexWhere(
        (e) => e.invoiceId == invoiceId,
      );
      if (todayIdx != -1) todayInvoices[todayIdx] = updated;
      invoices = allInvoices;
      selectedInvoice = updated;

      // Clear cached customer lookup — if action was 'credit', balance increased
      _lookedUpCustomer = null;

      // Refresh stats — credit action moves money between buckets on the dashboard
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

  // ── FETCH CUSTOMER BY MOBILE ──────────────────
  // Returns null when no customer exists. Result is also cached in
  // `lookedUpCustomer` so the create-invoice screen can show credit balance.
  Future<CustomerModel?> fetchCustomerByMobile(String mobile) async {
    try {
      _customerLookupLoading = true;
      notifyListeners();
      _lookedUpCustomer = await _api.fetchCustomerByMobile(mobile);
      return _lookedUpCustomer;
    } catch (e) {
      print('fetchCustomerByMobile error: $e');
      _lookedUpCustomer = null;
      return null;
    } finally {
      _customerLookupLoading = false;
      notifyListeners();
    }
  }

  // ── CLEAR Customer Lookup ─────────────────────
  void clearCustomerLookup() {
    _lookedUpCustomer = null;
    notifyListeners();
  }

  // ── CLEAR STATE ───────────────────────────────
  void clearSelected() {
    selectedInvoice = null;
    notifyListeners();
  }
}
