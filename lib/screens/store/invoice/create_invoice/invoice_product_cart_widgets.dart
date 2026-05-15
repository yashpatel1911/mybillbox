import 'package:flutter/material.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../model/product_model.dart';
import 'invoice_layout_widgets.dart';

// ─────────────────────────────────────────────────────
// InvoiceCartItem — mutable line item in the create-invoice cart.
// Lives here (not the main page) because both InvoiceProductRow and
// InvoiceCartRow reference it.
// ─────────────────────────────────────────────────────
class InvoiceCartItem {
  final ProductModel product;
  int qty;
  double unitPrice;
  String? selectedSize;
  double itemDiscount;

  InvoiceCartItem({
    required this.product,
    this.qty = 1,
    required this.unitPrice,
    this.selectedSize,
    this.itemDiscount = 0,
  });

  double get lineTotal => (unitPrice * qty) - itemDiscount;
}

// ─────────────────────────────────────────────────────
// InvoiceProductRow — one searchable product card with size chips + add btn
// ─────────────────────────────────────────────────────
class InvoiceProductRow extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final List<InvoiceCartItem> cartEntries;
  final ValueChanged<String?> onSizeSelected;
  final VoidCallback onAdd;

  const InvoiceProductRow({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.cartEntries,
    required this.onSizeSelected,
    required this.onAdd,
  });

  List<String> get _sizeOptions {
    if (product.isFreeSize) return ['Free Size'];
    final raw = product.sizes ?? '';
    if (raw.trim().isEmpty) return ['Free Size'];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sizesInCart =
    cartEntries.map((e) => e.selectedSize).whereType<String>().toSet();
    final sizes = _sizeOptions;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cartEntries.isNotEmpty ? AppColors.green : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.prodName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '₹${product.fixPrice?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (cartEntries.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cartEntries.length} added',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: selectedSize != null ? onAdd : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedSize != null
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedSize != null
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: selectedSize != null
                        ? AppColors.primary
                        : AppColors.textLight.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Size *',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sizes.map((s) {
                      final isSelected = selectedSize == s;
                      final alreadyInCart = sizesInCart.contains(s);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onSizeSelected(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 30,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : alreadyInCart
                                  ? AppColors.green.withOpacity(0.1)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : alreadyInCart
                                    ? AppColors.green
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : alreadyInCart
                                        ? AppColors.green
                                        : AppColors.textMedium,
                                  ),
                                ),
                                if (alreadyInCart && !isSelected) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          if (selectedSize == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '↑ Select a size to add this product',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.orange.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// InvoiceCartRow — selected item with editable price + qty controls
// ─────────────────────────────────────────────────────
class InvoiceCartRow extends StatelessWidget {
  final InvoiceCartItem item;
  final VoidCallback onIncrement, onDecrement, onRemove;
  final ValueChanged<String> onPriceChanged;

  const InvoiceCartRow({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.product.prodName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.selectedSize != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          item.selectedSize!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price (₹)',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        initialValue: item.unitPrice.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        onChanged: onPriceChanged,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Qty',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      InvoiceQtyBtn(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      InvoiceQtyBtn(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${item.lineTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// InvoiceSplitPaymentRow — toggle + amount field for one payment method.
// Used for Cash, Online, and Credit on Step 3. Optional helperText
// renders under the label (used to show "Available: ₹500" for credit).
// ─────────────────────────────────────────────────────
class InvoiceSplitPaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final String? helperText;

  const InvoiceSplitPaymentRow({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.05) : AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? color : AppColors.border,
          width: isEnabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!isEnabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isEnabled ? color : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isEnabled
                  ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: isEnabled ? color : AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? color : AppColors.textMedium,
                  ),
                ),
                if (helperText != null)
                  Text(
                    helperText!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isEnabled
                          ? color.withOpacity(0.8)
                          : AppColors.textLight,
                    ),
                  ),
              ],
            ),
          ),
          if (isEnabled)
            SizedBox(
              width: 110,
              height: 36,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: onChanged,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: color.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color),
                  ),
                ),
              ),
            )
          else
            Text(
              'Tap to enable',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}