// Expenses report model — mirrors /api/app/reports/expenses/ response.

double _d(dynamic v) => v == null
    ? 0.0
    : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

// ─────────────────────────────────────────────────────────────
// Overview totals (top 3 cards)
// ─────────────────────────────────────────────────────────────
class ExpensesOverview {
  final double totalSpent;
  final double purchasesTotal;
  final double expensesTotal;
  final int purchaseCount;
  final int expenseCount;
  final int totalCount;

  ExpensesOverview({
    required this.totalSpent,
    required this.purchasesTotal,
    required this.expensesTotal,
    required this.purchaseCount,
    required this.expenseCount,
    required this.totalCount,
  });

  factory ExpensesOverview.fromJson(Map<String, dynamic> j) => ExpensesOverview(
    totalSpent: _d(j['total_spent']),
    purchasesTotal: _d(j['purchases_total']),
    expensesTotal: _d(j['expenses_total']),
    purchaseCount: _i(j['purchase_count']),
    expenseCount: _i(j['expense_count']),
    totalCount: _i(j['total_count']),
  );

  factory ExpensesOverview.empty() => ExpensesOverview(
    totalSpent: 0,
    purchasesTotal: 0,
    expensesTotal: 0,
    purchaseCount: 0,
    expenseCount: 0,
    totalCount: 0,
  );
}

// ─────────────────────────────────────────────────────────────
// Category breakdown row (donut + top categories list)
// ─────────────────────────────────────────────────────────────
class ExpenseCategoryEntry {
  final int? catId; // null = synthetic "Stock Purchase"
  final String catName;
  final bool isPurchase; // true → Stock Purchase pseudo row
  final double total;
  final int count;

  ExpenseCategoryEntry({
    required this.catId,
    required this.catName,
    required this.isPurchase,
    required this.total,
    required this.count,
  });

  factory ExpenseCategoryEntry.fromJson(Map<String, dynamic> j) =>
      ExpenseCategoryEntry(
        catId: j['cat_id'] == null ? null : _i(j['cat_id']),
        catName: (j['cat_name'] ?? '—').toString(),
        isPurchase: j['is_purchase'] == true,
        total: _d(j['total']),
        count: _i(j['count']),
      );
}

// ─────────────────────────────────────────────────────────────
// Purchase vs Expense split
// ─────────────────────────────────────────────────────────────
class SpendingSplit {
  final double purchases;
  final double expenses;
  final double purchasesPct;
  final double expensesPct;

  SpendingSplit({
    required this.purchases,
    required this.expenses,
    required this.purchasesPct,
    required this.expensesPct,
  });

  factory SpendingSplit.fromJson(Map<String, dynamic> j) => SpendingSplit(
    purchases: _d(j['purchases']),
    expenses: _d(j['expenses']),
    purchasesPct: _d(j['purchases_pct']),
    expensesPct: _d(j['expenses_pct']),
  );

  factory SpendingSplit.empty() =>
      SpendingSplit(purchases: 0, expenses: 0, purchasesPct: 0, expensesPct: 0);
}

// ─────────────────────────────────────────────────────────────
// Daily spending point
// ─────────────────────────────────────────────────────────────
class DailySpendingPoint {
  final DateTime date;
  final double purchases;
  final double expenses;

  DailySpendingPoint({
    required this.date,
    required this.purchases,
    required this.expenses,
  });

  double get total => purchases + expenses;

  factory DailySpendingPoint.fromJson(Map<String, dynamic> j) =>
      DailySpendingPoint(
        date: DateTime.parse(j['date'] as String),
        purchases: _d(j['purchases']),
        expenses: _d(j['expenses']),
      );
}

// ─────────────────────────────────────────────────────────────
// Payment method entry (CASH / ONLINE)
// ─────────────────────────────────────────────────────────────
class ExpensePaymentMethodEntry {
  final String method;
  final double total;
  final int count;

  ExpensePaymentMethodEntry({
    required this.method,
    required this.total,
    required this.count,
  });

  factory ExpensePaymentMethodEntry.fromJson(Map<String, dynamic> j) =>
      ExpensePaymentMethodEntry(
        method: (j['payment_method'] ?? '').toString().toUpperCase(),
        total: _d(j['total']),
        count: _i(j['count']),
      );

  String get displayLabel {
    switch (method) {
      case 'CASH':
        return 'Cash';
      case 'ONLINE':
        return 'Online';
      default:
        return method;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Root model
// ─────────────────────────────────────────────────────────────
class ExpensesReport {
  final ExpensesOverview overview;
  final List<ExpenseCategoryEntry> categories;
  final SpendingSplit split;
  final List<DailySpendingPoint> dailySpending;
  final List<ExpensePaymentMethodEntry> paymentMethods;

  ExpensesReport({
    required this.overview,
    required this.categories,
    required this.split,
    required this.dailySpending,
    required this.paymentMethods,
  });

  factory ExpensesReport.fromJson(Map<String, dynamic> j) => ExpensesReport(
    overview: ExpensesOverview.fromJson(j['overview'] ?? {}),
    categories: (j['categories'] as List? ?? [])
        .map((e) => ExpenseCategoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    split: SpendingSplit.fromJson(j['split'] ?? {}),
    dailySpending: (j['daily_spending'] as List? ?? [])
        .map((e) => DailySpendingPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
    paymentMethods: (j['payment_methods'] as List? ?? [])
        .map(
          (e) => ExpensePaymentMethodEntry.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
  );

  factory ExpensesReport.empty() => ExpensesReport(
    overview: ExpensesOverview.empty(),
    categories: [],
    split: SpendingSplit.empty(),
    dailySpending: [],
    paymentMethods: [],
  );
}
