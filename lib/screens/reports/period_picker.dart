// Period picker — horizontal pills + computed range display.
// Single source of truth for "what data is shown" on the reports screen.

import 'package:flutter/material.dart';
import 'package:mybillbox/screens/reports/report_period.dart';

class PeriodPicker extends StatelessWidget {
  final ReportPeriod current;
  final ValueChanged<ReportPeriod> onChanged;
  final Color accentColor;

  const PeriodPicker({
    super.key,
    required this.current,
    required this.onChanged,
    this.accentColor = const Color(0xFF1A3C6E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pill row ──────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _Pill(
                  label: 'Today',
                  active: current.type == ReportPeriodType.today,
                  accent: accentColor,
                  onTap: () => onChanged(ReportPeriod.today()),
                ),
                _Pill(
                  label: 'Week',
                  active: current.type == ReportPeriodType.week,
                  accent: accentColor,
                  onTap: () => onChanged(ReportPeriod.thisWeek()),
                ),
                _Pill(
                  label: 'Month',
                  active: current.type == ReportPeriodType.month,
                  accent: accentColor,
                  onTap: () => onChanged(ReportPeriod.thisMonth()),
                ),
                _Pill(
                  label: 'Custom',
                  active: current.type == ReportPeriodType.custom,
                  accent: accentColor,
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _pickCustomRange(context),
                ),
              ],
            ),
          ),

          // ── Computed range display ────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: accentColor.withValues(alpha: 0.04),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    current.displayRange(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                Text(
                  '${current.dayCount} ${current.dayCount == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: accentColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      onChanged(ReportPeriod.custom(picked.start, picked.end));
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accent;

  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: active ? accent : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: active ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}