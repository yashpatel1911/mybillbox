import 'package:flutter/material.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../model/invoice_details/customer_model.dart';

/// Pill widget shown under the mobile field on Step 1.
/// Renders one of three states: loading, returning customer with credit,
/// returning customer without credit. Returns SizedBox.shrink() when
/// no customer was found (new customer case).
class InvoiceCustomerPill extends StatelessWidget {
  final bool loading;
  final CustomerModel? customer;
  final String Function(double) formatter;

  const InvoiceCustomerPill({
    super.key,
    required this.loading,
    required this.customer,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking customer records...',
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

    if (customer == null) return const SizedBox.shrink();

    final c = customer!;
    final hasCredit = c.creditBalance > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hasCredit
              ? AppColors.green.withOpacity(0.08)
              : AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasCredit
                ? AppColors.green.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasCredit
                  ? Icons.account_balance_wallet_rounded
                  : Icons.person_outline_rounded,
              size: 14,
              color: hasCredit ? AppColors.green : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Returning customer · ${c.name}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: hasCredit ? AppColors.green : AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasCredit)
                    Text(
                      '${formatter(c.creditBalance)} credit available',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}