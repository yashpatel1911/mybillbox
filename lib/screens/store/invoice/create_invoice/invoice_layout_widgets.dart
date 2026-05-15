import 'package:flutter/material.dart';
import '../../../../DBHelper/app_colors.dart';

// ─────────────────────────────────────────────────────
// InvoiceCard — labeled container used across all 3 steps
// ─────────────────────────────────────────────────────
class InvoiceCard extends StatelessWidget {
  final String title;
  final Widget child;

  const InvoiceCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceField — small label above a form widget
// ─────────────────────────────────────────────────────
class InvoiceField extends StatelessWidget {
  final String label;
  final Widget child;

  const InvoiceField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceStepIndicator — 1 ─ 2 ─ 3 progress at top of page
// ─────────────────────────────────────────────────────
class InvoiceStepIndicator extends StatelessWidget {
  final int step;

  const InvoiceStepIndicator({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _StepDot(n: 1, current: step, label: 'Customer'),
          _StepLine(done: step > 1),
          _StepDot(n: 2, current: step, label: 'Products'),
          _StepLine(done: step > 2),
          _StepDot(n: 3, current: step, label: 'Review'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n, current;
  final String label;

  const _StepDot({required this.n, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final done = n < current;
    final active = n == current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.green.withOpacity(0.15)
                : active
                ? AppColors.primary
                : Colors.transparent,
            border: Border.all(
              color: done
                  ? AppColors.green
                  : active
                  ? AppColors.primary
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check, size: 14, color: AppColors.green)
                : Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;

  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 18),
      color: done ? AppColors.green : AppColors.border,
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceStatusChip — Pending / Partial / Paid selector
// ─────────────────────────────────────────────────────
class InvoiceStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const InvoiceStatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.textLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceDiscBtn — Flat / Percent / None
// ─────────────────────────────────────────────────────
class InvoiceDiscBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const InvoiceDiscBtn({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.pageBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textMedium,
            ),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceQtyBtn — small + / − for cart row quantity
// ─────────────────────────────────────────────────────
class InvoiceQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const InvoiceQtyBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 14, color: AppColors.textDark),
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoiceSummaryRow — label + amount row in Summary card
// ─────────────────────────────────────────────────────
class InvoiceSummaryRow extends StatelessWidget {
  final String label, value;
  final bool isRed;

  const InvoiceSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isRed ? AppColors.red : AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────
// InvoicePaySummaryRow — colored label + value in payment summary box
// ─────────────────────────────────────────────────────
class InvoicePaySummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;

  const InvoicePaySummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}