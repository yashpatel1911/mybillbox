class InvoicePaymentModel {
  final int paymentId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String note;
  final String createdAt;

  InvoicePaymentModel({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.note,
    required this.createdAt,
  });

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentModel(
      paymentId:     json['payment_id']     as int,
      amount:        _d(json['amount']),
      paymentMethod: json['payment_method'] as String,
      paymentDate:   json['payment_date']   as String,
      note:          json['note']           as String? ?? '',
      createdAt:     json['created_at']     as String? ?? '',
    );
  }
}
class InvoicePaymentSummaryModel {
  final int invoiceId;
  final String invoiceNumber;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus;
  final List<InvoicePaymentModel> payments;

  InvoicePaymentSummaryModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.paymentStatus,
    required this.payments,
  });

  factory InvoicePaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentSummaryModel(
      invoiceId:     json['invoice_id'],
      invoiceNumber: json['invoice_number'],
      totalAmount:   double.parse(json['total_amount'].toString()),
      amountPaid:    double.parse(json['amount_paid'].toString()),
      amountDue:     double.parse(json['amount_due'].toString()),
      paymentStatus: json['payment_status'],
      payments: (json['payments'] as List)
          .map((e) => InvoicePaymentModel.fromJson(e))
          .toList(),
    );
  }
}