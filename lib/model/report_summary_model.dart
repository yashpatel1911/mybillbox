// Data model mirroring the /api/reports/summary/ response.
// Backend sends Decimal as String (for precision) — we parse to double here.

double _d(dynamic v) =>
    v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

class RevenueData {
  final double totalInvoiced;
  final double totalCollected;
  final double totalOutstanding;
  final int invoiceCount;

  RevenueData({
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.invoiceCount,
  });

  factory RevenueData.fromJson(Map<String, dynamic> j) => RevenueData(
    totalInvoiced: _d(j['total_invoiced']),
    totalCollected: _d(j['total_collected']),
    totalOutstanding: _d(j['total_outstanding']),
    invoiceCount: _i(j['invoice_count']),
  );

  factory RevenueData.empty() => RevenueData(
    totalInvoiced: 0,
    totalCollected: 0,
    totalOutstanding: 0,
    invoiceCount: 0,
  );
}

class SpendingData {
  final double purchasesTotal;
  final double purchasesPaid;
  final double purchasesDue;
  final double expensesTotal;
  final double totalOutflow;
  final int purchaseCount;
  final int expenseCount;

  SpendingData({
    required this.purchasesTotal,
    required this.purchasesPaid,
    required this.purchasesDue,
    required this.expensesTotal,
    required this.totalOutflow,
    required this.purchaseCount,
    required this.expenseCount,
  });

  factory SpendingData.fromJson(Map<String, dynamic> j) => SpendingData(
    purchasesTotal: _d(j['purchases_total']),
    purchasesPaid: _d(j['purchases_paid']),
    purchasesDue: _d(j['purchases_due']),
    expensesTotal: _d(j['expenses_total']),
    totalOutflow: _d(j['total_outflow']),
    purchaseCount: _i(j['purchase_count']),
    expenseCount: _i(j['expense_count']),
  );

  factory SpendingData.empty() => SpendingData(
    purchasesTotal: 0,
    purchasesPaid: 0,
    purchasesDue: 0,
    expensesTotal: 0,
    totalOutflow: 0,
    purchaseCount: 0,
    expenseCount: 0,
  );
}

class ProfitData {
  final double cashIn;
  final double cashOut;
  final double netProfit;
  final double marginPct;

  ProfitData({
    required this.cashIn,
    required this.cashOut,
    required this.netProfit,
    required this.marginPct,
  });

  bool get isProfit => netProfit >= 0;

  factory ProfitData.fromJson(Map<String, dynamic> j) => ProfitData(
    cashIn: _d(j['cash_in']),
    cashOut: _d(j['cash_out']),
    netProfit: _d(j['net_profit']),
    marginPct: _d(j['margin_pct']),
  );

  factory ProfitData.empty() =>
      ProfitData(cashIn: 0, cashOut: 0, netProfit: 0, marginPct: 0);
}

class DailyTrendPoint {
  final DateTime date;
  final double revenue;
  final double expenses;

  DailyTrendPoint({
    required this.date,
    required this.revenue,
    required this.expenses,
  });

  factory DailyTrendPoint.fromJson(Map<String, dynamic> j) => DailyTrendPoint(
    date: DateTime.parse(j['date'] as String),
    revenue: _d(j['revenue']),
    expenses: _d(j['expenses']),
  );
}

class ReportSummary {
  final RevenueData revenue;
  final SpendingData spending;
  final ProfitData profit;
  final List<DailyTrendPoint> dailyTrend;

  ReportSummary({
    required this.revenue,
    required this.spending,
    required this.profit,
    required this.dailyTrend,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
    revenue: RevenueData.fromJson(j['revenue'] ?? {}),
    spending: SpendingData.fromJson(j['spending'] ?? {}),
    profit: ProfitData.fromJson(j['profit'] ?? {}),
    dailyTrend: (j['daily_trend'] as List? ?? [])
        .map((e) => DailyTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  factory ReportSummary.empty() => ReportSummary(
    revenue: RevenueData.empty(),
    spending: SpendingData.empty(),
    profit: ProfitData.empty(),
    dailyTrend: [],
  );
}