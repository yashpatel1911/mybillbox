import 'package:mybillbox/model/purchase_details/purchase_dashboard_stats_model.dart';
import '../DBHelper/environment.dart';
import '../DBHelper/session_manager.dart';
import '../DBHelper/wp-api.dart';
import '../model/purchase_details/purchase_model.dart';
import '../model/purchase_details/purchase_payment_model.dart';

class PurchaseApiService {
  final SessionManager _setting = SessionManager();

  String get _token => _setting.token;

  // ──────────────────────────────────────────────────
  // Helper: build query map, dropping null/empty values
  // ──────────────────────────────────────────────────
  Map<String, String> _filterParams(Map<String, String?> raw) {
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (v != null && v.isNotEmpty) out[k] = v;
    });
    return out;
  }

  // ──────────────────────────────────────────────────
  // DASHBOARD STATS
  // ──────────────────────────────────────────────────
  Future<PurchaseDashboardStatsWrapper> fetchPurchaseDashboardStats({
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final body =
        await Api.get(
              Environment().dashboardStatsPurchase,
              query: _filterParams({
                'payment_status': paymentStatus,
                'date_from': dateFrom,
                'date_to': dateTo,
                'search': search,
              }),
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return PurchaseDashboardStatsWrapper.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch dashboard stats');
  }

  // ──────────────────────────────────────────────────
  // FETCH PURCHASE LIST (paginated)
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchPurchasePage({
    required int page,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
    int pageSize = 10,
  }) async {
    final body =
        await Api.get(
              Environment().getPurchase,
              query: _filterParams({
                'page': '$page',
                'page_size': '$pageSize',
                'payment_status': paymentStatus,
                'date_from': dateFrom,
                'date_to': dateTo,
                'search': search,
              }),
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to fetch purchases');
  }

  // ──────────────────────────────────────────────────
  // FETCH SINGLE Purchase
  // ──────────────────────────────────────────────────
  Future<PurchaseModel> fetchPurchaseById(int purchaseId) async {
    final body =
        await Api.get(
              '${Environment().getPurchaseById}$purchaseId/',
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return PurchaseModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Purchase not found');
  }

  // ──────────────────────────────────────────────────
  // CREATE Purchase
  // ──────────────────────────────────────────────────
  // payments = [{'method': 'cash', 'amount': 300}, {'method': 'online', 'amount': 200}]
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
    final body = <String, dynamic>{
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      'purchase_date': purchaseDate,
      'items': items,
      'discount_value': discountValue,
      'payment_status': paymentStatus,
      'payments': payments,
      if (notes != null) 'notes': notes,
      if (discountType != null) 'discount_type': discountType,
      if (paymentDate != null) 'payment_date': paymentDate,
    };

    return await Api.post(Environment().createPurchase, body, token: _token)
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // UPDATE Purchase
  // ──────────────────────────────────────────────────
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
    final body = <String, dynamic>{
      if (customerName != null) 'customer_name': customerName,
      if (customerMobile != null) 'customer_mobile': customerMobile,
      if (notes != null) 'notes': notes,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (items != null) 'items': items,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (payments.isNotEmpty) 'payments': payments,
    };

    return await Api.patch(
          '${Environment().updatePurchase}$purchaseId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // CANCEL Purchase
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelPurchase(int purchaseId) async {
    return await Api.delete(
          '${Environment().cancelPurchase}$purchaseId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // ADD PAYMENT
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> addPayment({
    required int purchaseId,
    required List<Map<String, dynamic>> payments,
    String? paymentDate,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'payments': payments,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (note != null) 'note': note,
    };

    return await Api.post(
          '${Environment().addPurchasePayment}$purchaseId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // FETCH PAYMENT HISTORY
  // ──────────────────────────────────────────────────
  Future<PurchasePaymentSummaryModel> fetchPayments(int purchaseId) async {
    final body =
        await Api.get(
              '${Environment().fetchPurchasePayments}$purchaseId/',
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return PurchasePaymentSummaryModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch payments');
  }
}
