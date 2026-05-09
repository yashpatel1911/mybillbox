import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybillbox/screens/store/invoice/invoice_details/product_cart_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../model/invoic_details/cart_item_model.dart';
import '../../../../model/invoice_model.dart';
import '../../../../model/product_model.dart';
import '../../../../provider/product_provider.dart';
import 'invoice_widgets.dart';

// ─── Customer / date / notes edit card ───────────────
class EditCustomerCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController mobileCtrl;
  final TextEditingController notesCtrl;
  final DateTime invoiceDate;
  final ValueChanged<DateTime> onDateChanged;

  const EditCustomerCard({
    super.key,
    required this.nameCtrl,
    required this.mobileCtrl,
    required this.notesCtrl,
    required this.invoiceDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Customer Details',
      child: Column(
        children: [
          EditField(
            label: 'Customer Name *',
            controller: nameCtrl,
            hint: 'e.g. Rajesh Electronics',
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          EditField(
            label: 'Mobile Number *',
            controller: mobileCtrl,
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
          const SizedBox(height: 10),
          // Date picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice Date *',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMedium),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: invoiceDate,
                    firstDate: DateTime(2020),
                    lastDate:
                    DateTime.now().add(const Duration(days: 30)),
                  );
                  if (d != null) onDateChanged(d);
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(invoiceDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          EditField(
            label: 'Notes (optional)',
            controller: notesCtrl,
            hint: 'Any note for this invoice',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Product search + cart card ───────────────────────
class EditProductsCard extends StatelessWidget {
  final Map<String, CartItem> cart;
  final Map<int, String?> pendingSize;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final double subTotal;
  final String Function(double) fmt;
  final VoidCallback onSearchClear;
  final ValueChanged<String> onSearchChanged;
  final void Function(ProductModel) onAddToCart;
  final void Function(String, String?) onSizeSelected;
  final void Function(String) onRemoveFromCart;
  final void Function(String) onIncrement;
  final void Function(String) onDecrement;
  final void Function(String, String) onPriceChanged;

  const EditProductsCard({
    super.key,
    required this.cart,
    required this.pendingSize,
    required this.searchCtrl,
    required this.searchQuery,
    required this.subTotal,
    required this.fmt,
    required this.onSearchClear,
    required this.onSearchChanged,
    required this.onAddToCart,
    required this.onSizeSelected,
    required this.onRemoveFromCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (ctx, provider, _) {
        return DetailCard(
          title: 'Products',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search products to add...',
                  hintStyle: const TextStyle(
                      color: AppColors.textLight, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textLight),
                  suffixIcon: searchQuery.isNotEmpty
                      ? GestureDetector(
                    onTap: onSearchClear,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textLight),
                  )
                      : null,
                  filled: true,
                  fillColor: AppColors.pageBg,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Product list
              if (provider.loadProduct)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              else if (provider.productList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    searchQuery.isNotEmpty
                        ? 'No products match "$searchQuery"'
                        : 'No products found',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.productList.length +
                      (provider.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.productList.length) {
                      WidgetsBinding.instance.addPostFrameCallback(
                            (_) =>
                            context.read<ProductProvider>().loadMore(),
                      );
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary),
                          ),
                        ),
                      );
                    }
                    final p = provider.productList[i];
                    return EditProductRow(
                      product: p,
                      selectedSize: pendingSize[p.prodId],
                      addedCount: cart.keys
                          .where((k) => k.startsWith('${p.prodId}_'))
                          .length,
                      onSizeSelected: (size) =>
                          onSizeSelected(p.prodId.toString(), size),
                      onAdd: () => onAddToCart(p),
                    );
                  },
                ),
              // Cart items
              if (cart.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.border),
                Text(
                  'Selected Items (${cart.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...cart.entries.map(
                      (entry) => EditCartRow(
                    item: entry.value,
                    onIncrement: () => onIncrement(entry.key),
                    onDecrement: () => onDecrement(entry.key),
                    onRemove: () => onRemoveFromCart(entry.key),
                    onPriceChanged: (v) =>
                        onPriceChanged(entry.key, v),
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium)),
                    Text(
                      '₹${fmt(subTotal)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Discount card ───────────────────────────────────
class EditDiscountCard extends StatelessWidget {
  final String? discountType;
  final TextEditingController discValCtrl;
  final ValueChanged<String?> onTypeChanged;

  const EditDiscountCard({
    super.key,
    required this.discountType,
    required this.discValCtrl,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Discount (optional)',
      child: Column(
        children: [
          Row(
            children: [
              DiscBtn(
                label: 'Flat ₹',
                active: discountType == 'flat',
                onTap: () => onTypeChanged('flat'),
              ),
              const SizedBox(width: 8),
              DiscBtn(
                label: 'Percent %',
                active: discountType == 'percent',
                onTap: () => onTypeChanged('percent'),
              ),
              const SizedBox(width: 8),
              DiscBtn(
                label: 'None',
                active: discountType == null,
                onTap: () => onTypeChanged(null),
              ),
            ],
          ),
          if (discountType != null) ...[
            const SizedBox(height: 10),
            TextField(
              controller: discValCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: discountType == 'flat'
                    ? 'Amount in ₹'
                    : 'Percent 0–100',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                filled: true,
                fillColor: AppColors.pageBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Payment status + new payment entry card ─────────
class EditPaymentCard extends StatelessWidget {
  final InvoiceModel invoice;
  final String paymentStatus;
  final bool useCash;
  final bool useOnline;
  final TextEditingController cashCtrl;
  final TextEditingController onlineCtrl;
  final double editTotal;
  final String Function(double) fmt;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onCashToggle;
  final ValueChanged<bool> onOnlineToggle;
  final ValueChanged<String> onCashChanged;
  final ValueChanged<String> onOnlineChanged;

  const EditPaymentCard({
    super.key,
    required this.invoice,
    required this.paymentStatus,
    required this.useCash,
    required this.useOnline,
    required this.cashCtrl,
    required this.onlineCtrl,
    required this.editTotal,
    required this.fmt,
    required this.onStatusChanged,
    required this.onCashToggle,
    required this.onOnlineToggle,
    required this.onCashChanged,
    required this.onOnlineChanged,
  });

  double get _cashAmount => double.tryParse(cashCtrl.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Payment Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Already paid banner
          if (invoice.amountPaid > 0) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: AppColors.green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Already paid',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium)),
                  Text(
                    '₹${fmt(invoice.amountPaid)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Status chips
          Row(
            children: [
              StatusChip(
                label: 'Pending',
                icon: Icons.schedule_rounded,
                color: AppColors.orange,
                selected: paymentStatus == 'pending',
                onTap: () => onStatusChanged('pending'),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: 'Partial',
                icon: Icons.pie_chart_outline_rounded,
                color: AppColors.primary,
                selected: paymentStatus == 'partial',
                onTap: () => onStatusChanged('partial'),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: 'Paid',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.green,
                selected: paymentStatus == 'paid',
                onTap: () => onStatusChanged('paid'),
              ),
            ],
          ),
          // New payment entry
          if (paymentStatus != 'pending') ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            const Text(
              'Add New Payment',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Enter cash/online for additional payment only',
              style:
              TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            SplitRow(
              icon: Icons.money_rounded,
              label: 'Cash',
              color: AppColors.green,
              isEnabled: useCash,
              controller: cashCtrl,
              onToggle: onCashToggle,
              onChanged: onCashChanged,
            ),
            const SizedBox(height: 8),
            SplitRow(
              icon: Icons.phone_android_rounded,
              label: 'Online',
              color: AppColors.primary,
              isEnabled: useOnline,
              controller: onlineCtrl,
              onToggle: onOnlineToggle,
              onChanged: onOnlineChanged,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Summary preview card (edit mode) ────────────────
class EditSummaryCard extends StatelessWidget {
  final double subTotal;
  final double discountAmt;
  final double editTotal;
  final double totalPaid;
  final bool showPayment;
  final String? discountType;
  final String Function(double) fmt;

  const EditSummaryCard({
    super.key,
    required this.subTotal,
    required this.discountAmt,
    required this.editTotal,
    required this.totalPaid,
    required this.showPayment,
    required this.discountType,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Summary Preview',
      child: Column(
        children: [
          DetailRow(label: 'Subtotal', value: '₹${fmt(subTotal)}'),
          if (discountType != null && discountAmt > 0)
            DetailRow(
              label: 'Discount',
              value: '− ₹${fmt(discountAmt)}',
              valueColor: AppColors.red,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '₹${fmt(editTotal)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          if (showPayment) ...[
            const SizedBox(height: 8),
            DetailRow(
              label: 'New Payment',
              value: '₹${fmt(totalPaid)}',
              valueColor: AppColors.green,
            ),
          ],
        ],
      ),
    );
  }
}