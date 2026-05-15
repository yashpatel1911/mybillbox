import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../DBHelper/app_constant.dart';
import '../../../../model/invoice_details/invoice_model.dart';
import '../../../../provider/invoice_provider.dart';

/// Shows an orange banner with two action buttons when the invoice has
/// an unresolved overpayment (customer paid more than the new total after
/// an item was removed during edit). Submitting either action calls the
/// backend's resolve-overpayment endpoint.
///
/// Two outcomes:
/// - 'refund' → shop hands back cash offline, invoice marked resolved
/// - 'credit' → amount added to customer.credit_balance (requires linked customer)
///
/// Both actions go through a confirmation dialog first since they are
/// irreversible and 'credit' affects the customer's future invoices.
class ResolveOverpaymentCard extends StatefulWidget {
  final InvoiceModel invoice;
  final String Function(double) fmt;
  final VoidCallback onResolved;

  const ResolveOverpaymentCard({
    super.key,
    required this.invoice,
    required this.fmt,
    required this.onResolved,
  });

  @override
  State<ResolveOverpaymentCard> createState() => _ResolveOverpaymentCardState();
}

class _ResolveOverpaymentCardState extends State<ResolveOverpaymentCard> {
  bool _submitting = false;

  // If overpayment is already resolved, show a small chip explaining what
  // happened instead of the action banner.
  bool get _alreadyResolved => widget.invoice.overpaymentResolved;

  Future<void> _onActionTap(String action) async {
    if (_submitting) return;

    // Block 'credit' when invoice has no linked customer (old invoice
    // backfilled with customer=NULL). Backend would reject anyway.
    if (action == 'credit' && !widget.invoice.hasCustomerLink) {
      AppConstant.warningMessage(
        'Cannot add to credit — this invoice has no linked customer record',
        context,
      );
      return;
    }

    final confirmed = await _showConfirmDialog(action);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      final res = await context.read<InvoiceProvider>().resolveOverpayment(
        invoiceId: widget.invoice.invoiceId,
        action: action,
      );
      if (!mounted) return;
      if (res['status'] == true) {
        AppConstant.successMessage(
          action == 'refund'
              ? 'Refund recorded — overpayment resolved'
              : '${widget.fmt(widget.invoice.overpaidAmount)} added to customer credit',
          context,
        );
        widget.onResolved();
      } else {
        AppConstant.errorMessage(
          res['message'] ?? 'Failed to resolve overpayment',
          context,
        );
      }
    } catch (e) {
      if (mounted) AppConstant.errorMessage('Error: $e', context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _showConfirmDialog(String action) async {
    final amount = widget.fmt(widget.invoice.overpaidAmount);
    final isCredit = action == 'credit';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isCredit ? 'Add to Credit?' : 'Confirm Refund?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          isCredit
              ? '$amount will be added to ${widget.invoice.customerName}\'s credit balance. '
              'They can use it on their next invoice.'
              : 'You will hand back $amount in cash to ${widget.invoice.customerName} outside the app. '
              'This action cannot be undone.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isCredit ? AppColors.green : AppColors.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isCredit ? 'Add to Credit' : 'Confirm Refund',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadyResolved) return _buildResolvedChip();
    return _buildActionBanner();
  }

  // ── Resolved state: small chip showing what happened ──
  Widget _buildResolvedChip() {
    final action = widget.invoice.overpaymentAction;
    final amount = widget.fmt(widget.invoice.overpaidAmount);
    if (action == 'none' || widget.invoice.overpaidAmount <= 0) {
      return const SizedBox.shrink();
    }

    final isCredit = action == 'credit';
    final color = isCredit ? AppColors.green : AppColors.primary;
    final label = isCredit
        ? '$amount added to customer credit'
        : '$amount refunded to customer';
    final icon = isCredit
        ? Icons.account_balance_wallet_rounded
        : Icons.payments_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overpayment resolved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }

  // ── Unresolved state: warning + two action buttons ──
  Widget _buildActionBanner() {
    final amount = widget.fmt(widget.invoice.overpaidAmount);
    final canAddCredit = widget.invoice.hasCustomerLink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overpaid by $amount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Customer paid more than the current total. Choose how to resolve:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: _ResolveBtn(
                  icon: Icons.payments_outlined,
                  label: 'Refund Cash',
                  color: AppColors.orange,
                  enabled: !_submitting,
                  onTap: () => _onActionTap('refund'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResolveBtn(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Add to Credit',
                  color: AppColors.green,
                  enabled: !_submitting && canAddCredit,
                  onTap: () => _onActionTap('credit'),
                ),
              ),
            ],
          ),

          if (!canAddCredit) ...[
            const SizedBox(height: 8),
            Text(
              'Note: this invoice has no linked customer, so credit is unavailable.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // ── Inline loading indicator ──
          if (_submitting) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Resolving...',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.orange.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolveBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ResolveBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        decoration: BoxDecoration(
          color: enabled ? color : AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: enabled ? Colors.white : AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}