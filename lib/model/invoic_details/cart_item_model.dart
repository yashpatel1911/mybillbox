// ─── Cart item model for edit ────────────────────────

class CartItem {
  final int productId;
  final String productName;
  int qty;
  double unitPrice;
  String? selectedSize;
  double itemDiscount;

  CartItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    this.selectedSize,
    this.itemDiscount = 0,
  });

  double get lineTotal => (unitPrice * qty) - itemDiscount;
}