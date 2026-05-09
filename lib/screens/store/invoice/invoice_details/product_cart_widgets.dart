import 'package:flutter/material.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../model/invoic_details/cart_item_model.dart';
import '../../../../model/product_model.dart';
import 'invoice_widgets.dart';

// ─── Edit product row ────────────────────────────────
class EditProductRow extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final int addedCount;
  final ValueChanged<String?> onSizeSelected;
  final VoidCallback onAdd;

  const EditProductRow({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.addedCount,
    required this.onSizeSelected,
    required this.onAdd,
  });

  List<String> get _sizes {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: addedCount > 0 ? AppColors.green : AppColors.border,
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
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              if (addedCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$addedCount added',
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedSize != null
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selectedSize != null
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: selectedSize != null
                        ? AppColors.primary
                        : AppColors.textLight.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
                    children: _sizes.map((s) {
                      final sel = selectedSize == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onSizeSelected(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 28,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textMedium,
                                ),
                              ),
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
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '↑ Select a size to add',
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

// ─── Edit cart row ───────────────────────────────────
class EditCartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement, onDecrement, onRemove;
  final ValueChanged<String> onPriceChanged;

  const EditCartRow({
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
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
                        item.productName,
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
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
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price field
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
                      height: 34,
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
                              horizontal: 10, vertical: 7),
                          filled: true,
                          fillColor: AppColors.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide:
                            BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide:
                            BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide:
                            BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Qty stepper
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
                      QtyBtn(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      QtyBtn(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Line total
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