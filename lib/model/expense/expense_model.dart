class ExpenseModel {
  final int expId;
  final String? partyName;
  final int? expCatId;
  final String? expCatName;
  final double amount;
  final String paidOn; // 'YYYY-MM-DD'
  final String paymentMethod; // 'CASH' | 'ONLINE'
  final String? notes;
  final int? shopId;
  final String? shopName;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  ExpenseModel({
    required this.expId,
    this.partyName,
    this.expCatId,
    this.expCatName,
    required this.amount,
    required this.paidOn,
    required this.paymentMethod,
    this.notes,
    this.shopId,
    this.shopName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expId: json['exp_id'] ?? 0,
      partyName: json['party_name'],
      expCatId: json['exp_cat_id'],
      expCatName: json['exp_cat_name'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidOn: json['paid_on']?.toString() ?? '',
      paymentMethod: json['payment_method'] ?? 'CASH',
      notes: json['notes'],
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class ExpenseSummary {
  final int totalCount;
  final double totalAmount;
  final double cashTotal;
  final double onlineTotal;

  ExpenseSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.cashTotal,
    required this.onlineTotal,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalCount: json['total_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      cashTotal: (json['cash_total'] ?? 0).toDouble(),
      onlineTotal: (json['online_total'] ?? 0).toDouble(),
    );
  }

  factory ExpenseSummary.empty() => ExpenseSummary(
    totalCount: 0,
    totalAmount: 0,
    cashTotal: 0,
    onlineTotal: 0,
  );
}