class CustomerModel {
  final int customerId;
  final String name;
  final String mobile;
  final double creditBalance;

  CustomerModel({
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.creditBalance,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customer_id'] as int,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      creditBalance: _toDouble(json['credit_balance']),
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'name': name,
    'mobile': mobile,
    'credit_balance': creditBalance,
  };

  /// Helper to safely parse Decimal/String/num from API into double.
  /// Django returns DecimalField values as strings in JSON.
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}