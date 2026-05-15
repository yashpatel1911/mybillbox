import '../DBHelper/environment.dart';
import '../DBHelper/session_manager.dart';
import '../DBHelper/wp-api.dart';
import '../model/invoice_details/customer_model.dart';
import '../model/invoice_details/dashboard_stats_model.dart';
import '../model/invoice_details/invoice_model.dart';
import '../model/invoice_details/invoice_payment_model.dart';

class InvoiceApiService {
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
  Future<DashboardStatsWrapper> fetchDashboardStats({
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final body =
        await Api.get(
              Environment().dashboardStats,
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
      return DashboardStatsWrapper.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch dashboard stats');
  }

  // ──────────────────────────────────────────────────
  // FETCH INVOICE LIST (paginated)
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchInvoicePage({
    required int page,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
    int pageSize = 10,
  }) async {
    final body =
        await Api.get(
              Environment().getInvoices,
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
    throw Exception(body['message'] ?? 'Failed to fetch invoices');
  }

  // ──────────────────────────────────────────────────
  // FETCH SINGLE INVOICE
  // ──────────────────────────────────────────────────
  Future<InvoiceModel> fetchInvoiceById(int invoiceId) async {
    final body =
        await Api.get(
              '${Environment().getInvoiceById}$invoiceId/',
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return InvoiceModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Invoice not found');
  }

  // ──────────────────────────────────────────────────
  // CREATE INVOICE
  // ──────────────────────────────────────────────────
  // payments = [{'method': 'cash', 'amount': 300}, {'method': 'online', 'amount': 200}]
  // creditToApply = amount to deduct from customer's existing credit balance
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
    final body = <String, dynamic>{
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      'invoice_date': invoiceDate,
      'items': items,
      'discount_value': discountValue,
      'credit_to_apply': creditToApply,
      'payment_status': paymentStatus,
      'payments': payments,
      if (notes != null) 'notes': notes,
      if (discountType != null) 'discount_type': discountType,
      if (paymentDate != null) 'payment_date': paymentDate,
    };

    return await Api.post(Environment().createInvoice, body, token: _token)
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // UPDATE INVOICE
  // ──────────────────────────────────────────────────
  // No signature change — backend now auto-detects overpayments and returns
  // overpaid_amount + overpayment_resolved in the response.
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
    final body = <String, dynamic>{
      if (customerName != null) 'customer_name': customerName,
      if (customerMobile != null) 'customer_mobile': customerMobile,
      if (notes != null) 'notes': notes,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (items != null) 'items': items,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (payments.isNotEmpty) 'payments': payments,
    };

    return await Api.patch(
          '${Environment().updateInvoice}$invoiceId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // CANCEL INVOICE
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelInvoice(int invoiceId) async {
    return await Api.delete(
          '${Environment().cancelInvoice}$invoiceId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // ADD PAYMENT
  // ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> addPayment({
    required int invoiceId,
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
          '${Environment().addInvoicePayment}$invoiceId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // FETCH PAYMENT HISTORY
  // ──────────────────────────────────────────────────
  Future<InvoicePaymentSummaryModel> fetchPayments(int invoiceId) async {
    final body =
        await Api.get(
              '${Environment().fetchInvoicePayments}$invoiceId/',
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      return InvoicePaymentSummaryModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch payments');
  }

  // ──────────────────────────────────────────────────
  // RESOLVE OVERPAYMENT
  // ──────────────────────────────────────────────────
  // action must be 'refund' or 'credit'.
  // 'credit' adds the overpaid_amount to customer.credit_balance.
  // 'refund' just marks resolved — shop hands back cash outside the system.
  Future<Map<String, dynamic>> resolveOverpayment({
    required int invoiceId,
    required String action,
  }) async {
    final body = <String, dynamic>{'action': action};

    return await Api.patch(
          '${Environment().resolveOverpayment}$invoiceId/resolve-overpayment/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // FETCH CUSTOMER BY MOBILE
  // ──────────────────────────────────────────────────
  // Returns null when no customer exists for this mobile in current shop.
  // Used before creating an invoice to check available credit balance.
  Future<CustomerModel?> fetchCustomerByMobile(String mobile) async {
    final body =
        await Api.get(
              Environment().getCustomerByMobile,
              query: _filterParams({'mobile': mobile}),
              token: _token,
            )
            as Map<String, dynamic>;

    if (body['status'] == true) {
      final data = body['data'];
      if (data == null) return null;
      return CustomerModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to fetch customer');
  }
}
