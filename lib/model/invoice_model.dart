class InvoiceItemModel {
  final int itemId;
  final int productId;
  final String productName;
  final String categoryName;
  final String? size;
  final int quantity;
  final double unitPrice;
  final double itemDiscount;
  final double totalPrice;

  InvoiceItemModel({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.categoryName,
    this.size,
    required this.quantity,
    required this.unitPrice,
    required this.itemDiscount,
    required this.totalPrice,
  });

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      itemId:       json['item_id']       as int,
      productId:    json['product_id']    as int,
      productName:  json['product_name']  as String,
      categoryName: json['category_name'] as String,
      size:         json['size']          as String?,
      quantity:     json['quantity']      as int,
      unitPrice:    _d(json['unit_price']),
      itemDiscount: _d(json['item_discount']),
      totalPrice:   _d(json['total_price']),
    );
  }
}

class InvoiceShopModel {
  final int shId;
  final String shName;

  InvoiceShopModel({required this.shId, required this.shName});

  factory InvoiceShopModel.fromJson(Map<String, dynamic> json) =>
      InvoiceShopModel(shId: json['sh_id'], shName: json['sh_name']);
}

class InvoiceModel {
  final int invoiceId;
  final String invoiceNumber;
  final String invoiceDate;
  final InvoiceShopModel? shop;
  final String customerName;
  final String customerMobile;
  final double subTotal;
  final String? discountType;
  final double discountValue;
  final double discountAmount;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus;
  final String notes;
  final bool isCancelled;
  final String createdAt;
  final List<InvoiceItemModel> items;

  InvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.shop,
    required this.customerName,
    required this.customerMobile,
    required this.subTotal,
    this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.paymentStatus,
    required this.notes,
    required this.isCancelled,
    required this.createdAt,
    this.items = const [],
  });

  // ── Safe double parse — never crashes on null ──
  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId:      json['invoice_id']      as int,
      invoiceNumber:  json['invoice_number']  as String,
      invoiceDate:    json['invoice_date']    as String,
      shop:           json['shop'] != null
          ? InvoiceShopModel.fromJson(json['shop'])
          : null,
      customerName:   json['customer_name']   as String,
      customerMobile: json['customer_mobile'] as String,
      subTotal:       _d(json['sub_total']),
      discountType:   json['discount_type']   as String?,
      discountValue:  _d(json['discount_value']),
      discountAmount: _d(json['discount_amount']),
      totalAmount:    _d(json['total_amount']),
      amountPaid:     _d(json['amount_paid']),
      amountDue:      _d(json['amount_due']),
      paymentStatus:  json['payment_status']  as String? ?? 'pending',
      notes:          json['notes']           as String? ?? '',
      isCancelled:    json['is_cancelled']    as bool?   ?? false,
      createdAt:      json['created_at']      as String? ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
          .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }
}