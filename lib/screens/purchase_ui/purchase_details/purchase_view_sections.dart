import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybillbox/model/purchase_details/purchase_model.dart';
import 'package:mybillbox/provider/purchase_provider.dart';
import 'package:mybillbox/screens/purchase_ui/purchase_details/purchase_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../DBHelper/app_constant.dart';

// ─── Header card (purchase number + status badge) ─────
class PurchaseHeaderCard extends StatelessWidget {
  final PurchaseModel purchase;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const PurchaseHeaderCard({
    super.key,
    required this.purchase,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = statusColor(purchase.paymentStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                purchase.customerName[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Invoice number + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.purchaseNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  purchase.purchaseDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Status + cancelled badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel(purchase.paymentStatus),
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (purchase.isCancelled) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cancelled',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer details card ───────────────────────────
class PurchaseCustomerCard extends StatelessWidget {
  final PurchaseModel purchase;

  const PurchaseCustomerCard({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Customer Details',
      child: Column(
        children: [
          DetailRow(label: 'Name', value: purchase.customerName),
          DetailRow(label: 'Mobile', value: purchase.customerMobile),
          DetailRow(
            label: 'Date',
            value: DateFormat('dd MMM yyyy').format(
              DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now(),
            ),
          ),
          if (purchase.notes.isNotEmpty)
            DetailRow(label: 'Notes', value: purchase.notes),
        ],
      ),
    );
  }
}

// ─── Items list card ─────────────────────────────────
class PurchaseItemsCard extends StatelessWidget {
  final PurchaseModel purchase;
  final String Function(double) fmt;

  const PurchaseItemsCard({
    super.key,
    required this.purchase,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Items (${purchase.items.length})',
      child: Column(
        children: purchase.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      item.productName[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        [
                          if (item.size != null && item.size!.isNotEmpty)
                            'Size: ${item.size}',
                          '× ${item.quantity}  ·  ₹${fmt(item.unitPrice)} each',
                        ].join('   '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      if (item.itemDiscount > 0)
                        Text(
                          'Discount: ₹${fmt(item.itemDiscount)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${fmt(item.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Payment summary card ────────────────────────────
class PurchaseSummaryCard extends StatelessWidget {
  final PurchaseModel purchase;
  final String Function(double) fmt;

  const PurchaseSummaryCard({
    super.key,
    required this.purchase,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Payment Summary',
      child: Column(
        children: [
          DetailRow(label: 'Subtotal', value: '₹${fmt(purchase.subTotal)}'),
          if (purchase.discountType != null && purchase.discountAmount > 0)
            DetailRow(
              label:
                  'Discount (${purchase.discountType == 'percent' ? '${purchase.discountValue.toStringAsFixed(0)}%' : 'flat'})',
              value: '− ₹${fmt(purchase.discountAmount)}',
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
                '₹${fmt(purchase.totalAmount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DetailRow(
            label: 'Amount Paid',
            value: '₹${fmt(purchase.amountPaid)}',
            valueColor: AppColors.green,
          ),
          DetailRow(
            label: 'Amount Due',
            value: '₹${fmt(purchase.amountDue)}',
            valueColor: purchase.amountDue > 0
                ? AppColors.red
                : AppColors.green,
          ),
        ],
      ),
    );
  }
}

// ─── Record payment card (view mode only) ───────────
class AddPaymentCard extends StatefulWidget {
  final PurchaseModel purchase;
  final int purchaseId;
  final String Function(double) fmt;
  final VoidCallback onPaymentSuccess;

  const AddPaymentCard({
    super.key,
    required this.purchase,
    required this.purchaseId,
    required this.fmt,
    required this.onPaymentSuccess,
  });

  @override
  State<AddPaymentCard> createState() => _AddPaymentCardState();
}

class _AddPaymentCardState extends State<AddPaymentCard> {
  final _cashCtrl = TextEditingController();
  final _onlineCtrl = TextEditingController();
  bool _useCash = false;
  bool _useOnline = false;
  bool _paying = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _onlineCtrl.dispose();
    super.dispose();
  }

  double get _cashAmt => double.tryParse(_cashCtrl.text) ?? 0;

  double get _onlineAmt => double.tryParse(_onlineCtrl.text) ?? 0;

  double get _totalPaid =>
      (_useCash ? _cashAmt : 0) + (_useOnline ? _onlineAmt : 0);

  double get _amountDue => widget.purchase.amountDue;

  List<Map<String, dynamic>> get _payments {
    final list = <Map<String, dynamic>>[];
    if (_useCash && _cashAmt > 0)
      list.add({'method': 'cash', 'amount': _cashAmt});
    if (_useOnline && _onlineAmt > 0)
      list.add({'method': 'online', 'amount': _onlineAmt});
    return list;
  }

  Future<void> _submit() async {
    if (!_useCash && !_useOnline) {
      AppConstant.warningMessage('Select at least one payment method', context);
      return;
    }
    if (_totalPaid <= 0) {
      AppConstant.warningMessage('Enter a valid amount', context);
      return;
    }
    if (_totalPaid > _amountDue) {
      AppConstant.warningMessage('Total paid exceeds due amount', context);
      return;
    }
    setState(() => _paying = true);
    try {
      final res = await context.read<PurchaseProvider>().addPayment(
        purchaseId: widget.purchaseId,
        payments: _payments,
        paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      if (!mounted) return;
      if (res['status'] == true) {
        AppConstant.successMessage('Payment recorded!', context);
        _cashCtrl.clear();
        _onlineCtrl.clear();
        setState(() {
          _useCash = false;
          _useOnline = false;
        });
        widget.onPaymentSuccess();
      } else {
        AppConstant.errorMessage(res['message'] ?? 'Failed', context);
      }
    } catch (e) {
      AppConstant.errorMessage('Error: $e', context);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.fmt;
    return DetailCard(
      title: 'Record Payment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                'Due: ₹${fmt(_amountDue)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select one or both — enter amounts freely',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          SplitRow(
            icon: Icons.money_rounded,
            label: 'Cash',
            color: AppColors.green,
            isEnabled: _useCash,
            controller: _cashCtrl,
            onToggle: (val) => setState(() {
              _useCash = val;
              if (!val) _cashCtrl.text = '';
            }),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SplitRow(
            icon: Icons.phone_android_rounded,
            label: 'Online',
            color: AppColors.primary,
            isEnabled: _useOnline,
            controller: _onlineCtrl,
            onToggle: (val) => setState(() {
              _useOnline = val;
              if (!val) _onlineCtrl.text = '';
            }),
            onChanged: (_) => setState(() {}),
          ),
          if (_useCash || _useOnline) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pageBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (_useCash)
                    PayRow(
                      label: 'Cash',
                      value: '₹${fmt(_cashAmt)}',
                      color: AppColors.green,
                    ),
                  if (_useOnline)
                    PayRow(
                      label: 'Online',
                      value: '₹${fmt(_onlineAmt)}',
                      color: AppColors.primary,
                    ),
                  const Divider(height: 12, color: AppColors.border),
                  PayRow(
                    label: 'Total Paying',
                    value: '₹${fmt(_totalPaid)}',
                    color: AppColors.textDark,
                    bold: true,
                  ),
                  PayRow(
                    label: 'Remaining After',
                    value: (_amountDue - _totalPaid) > 0
                        ? '₹${fmt(_amountDue - _totalPaid)}'
                        : 'Fully Paid',
                    color: (_amountDue - _totalPaid) > 0
                        ? AppColors.orange
                        : AppColors.green,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _paying ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
