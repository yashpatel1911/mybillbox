class PurchasePaymentModel {
  final int paymentId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String note;
  final String createdAt;

  PurchasePaymentModel({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.note,
    required this.createdAt,
  });

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentModel(
      paymentId: json['payment_id'] as int,
      amount: _d(json['amount']),
      paymentMethod: json['payment_method'] as String,
      paymentDate: json['payment_date'] as String,
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class PurchasePaymentSummaryModel {
  final int purchaseId;
  final String purchaseNumber;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus;
  final List<PurchasePaymentModel> payments;

  PurchasePaymentSummaryModel({
    required this.purchaseId,
    required this.purchaseNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.paymentStatus,
    required this.payments,
  });

  factory PurchasePaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentSummaryModel(
      purchaseId: json['purchase_id'],
      purchaseNumber: json['purchase_number'],
      totalAmount: double.parse(json['total_amount'].toString()),
      amountPaid: double.parse(json['amount_paid'].toString()),
      amountDue: double.parse(json['amount_due'].toString()),
      paymentStatus: json['payment_status'],
      payments: (json['payments'] as List)
          .map((e) => PurchasePaymentModel.fromJson(e))
          .toList(),
    );
  }
}
