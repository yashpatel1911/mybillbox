// Sales report model — mirrors /api/app/reports_provider/sales/ response.

double _d(dynamic v) =>
    v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

// ─────────────────────────────────────────────────────────────
// Overview totals (top 3 cards)
// ─────────────────────────────────────────────────────────────
class SalesOverview {
  final double totalInvoiced;
  final double totalCollected;
  final double totalPending;
  final int invoiceCount;

  SalesOverview({
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalPending,
    required this.invoiceCount,
  });

  factory SalesOverview.fromJson(Map<String, dynamic> j) => SalesOverview(
    totalInvoiced: _d(j['total_invoiced']),
    totalCollected: _d(j['total_collected']),
    totalPending: _d(j['total_pending']),
    invoiceCount: _i(j['invoice_count']),
  );

  factory SalesOverview.empty() => SalesOverview(
    totalInvoiced: 0,
    totalCollected: 0,
    totalPending: 0,
    invoiceCount: 0,
  );
}

// ─────────────────────────────────────────────────────────────
// Daily revenue point (for bar chart)
// ─────────────────────────────────────────────────────────────
class DailyRevenuePoint {
  final DateTime date;
  final double revenue;

  DailyRevenuePoint({required this.date, required this.revenue});

  factory DailyRevenuePoint.fromJson(Map<String, dynamic> j) =>
      DailyRevenuePoint(
        date: DateTime.parse(j['date'] as String),
        revenue: _d(j['revenue']),
      );
}

// ─────────────────────────────────────────────────────────────
// Top product row
// ─────────────────────────────────────────────────────────────
class TopProduct {
  final int productId;
  final String productName;
  final int qtySold;
  final double revenue;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.qtySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
    productId: _i(j['product_id']),
    productName: (j['product_name'] ?? '—').toString(),
    qtySold: _i(j['qty_sold']),
    revenue: _d(j['revenue']),
  );
}

// ─────────────────────────────────────────────────────────────
// Top customer row
// ─────────────────────────────────────────────────────────────
class TopCustomer {
  final int? customerId;
  final String customerName;
  final String customerMobile;
  final double totalSpent;
  final int invoiceCount;

  TopCustomer({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.totalSpent,
    required this.invoiceCount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> j) => TopCustomer(
    customerId: j['customer_id'] == null ? null : _i(j['customer_id']),
    customerName: (j['customer_name'] ?? '—').toString(),
    customerMobile: (j['customer_mobile'] ?? '').toString(),
    totalSpent: _d(j['total_spent']),
    invoiceCount: _i(j['invoice_count']),
  );
}

// ─────────────────────────────────────────────────────────────
// Payment method split row
// ─────────────────────────────────────────────────────────────
class PaymentMethodEntry {
  final String method; // 'cash' | 'online' | 'credit' | 'refund'
  final double total;
  final int count;

  PaymentMethodEntry({
    required this.method,
    required this.total,
    required this.count,
  });

  factory PaymentMethodEntry.fromJson(Map<String, dynamic> j) =>
      PaymentMethodEntry(
        method: (j['payment_method'] ?? '').toString(),
        total: _d(j['total']),
        count: _i(j['count']),
      );

  // Convenience for UI display
  String get displayLabel {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'online':
        return 'Online';
      case 'credit':
        return 'Credit';
      case 'refund':
        return 'Refunds';
      default:
        return method;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Root model
// ─────────────────────────────────────────────────────────────
class SalesReport {
  final SalesOverview overview;
  final List<DailyRevenuePoint> dailyRevenue;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;
  final List<PaymentMethodEntry> paymentMethods;

  SalesReport({
    required this.overview,
    required this.dailyRevenue,
    required this.topProducts,
    required this.topCustomers,
    required this.paymentMethods,
  });

  factory SalesReport.fromJson(Map<String, dynamic> j) => SalesReport(
    overview: SalesOverview.fromJson(j['overview'] ?? {}),
    dailyRevenue: (j['daily_revenue'] as List? ?? [])
        .map((e) => DailyRevenuePoint.fromJson(e as Map<String, dynamic>))
        .toList(),
    topProducts: (j['top_products'] as List? ?? [])
        .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
        .toList(),
    topCustomers: (j['top_customers'] as List? ?? [])
        .map((e) => TopCustomer.fromJson(e as Map<String, dynamic>))
        .toList(),
    paymentMethods: (j['payment_methods'] as List? ?? [])
        .map((e) =>
        PaymentMethodEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  factory SalesReport.empty() => SalesReport(
    overview: SalesOverview.empty(),
    dailyRevenue: [],
    topProducts: [],
    topCustomers: [],
    paymentMethods: [],
  );
}