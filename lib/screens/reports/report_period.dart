// Period selection model — drives the entire reports screen.
// Owns the "what range is currently selected" + computes the actual
// from/to dates that get sent to the API.

import 'package:flutter/material.dart';

enum ReportPeriodType {
  today,
  week, // this week (Mon-Sun)
  month, // this month
  custom, // user-picked range
  compare, // two ranges side-by-side (phase 2 — stub for now)
}

class ReportPeriod {
  final ReportPeriodType type;
  final DateTime from;
  final DateTime to;

  const ReportPeriod({
    required this.type,
    required this.from,
    required this.to,
  });

  // ── Factory constructors for each preset ──────────────────
  factory ReportPeriod.today() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return ReportPeriod(type: ReportPeriodType.today, from: d, to: d);
  }

  factory ReportPeriod.thisWeek() {
    final now = DateTime.now();
    // Monday-based week (DateTime.weekday: Mon=1, Sun=7)
    final mondayOffset = now.weekday - 1;
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: mondayOffset));
    final sunday = monday.add(const Duration(days: 6));
    return ReportPeriod(
      type: ReportPeriodType.week,
      from: monday,
      to: sunday,
    );
  }

  factory ReportPeriod.thisMonth() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    // Last day of month = day 0 of next month
    final last = DateTime(now.year, now.month + 1, 0);
    return ReportPeriod(
      type: ReportPeriodType.month,
      from: first,
      to: last,
    );
  }

  factory ReportPeriod.custom(DateTime from, DateTime to) {
    return ReportPeriod(
      type: ReportPeriodType.custom,
      from: DateTime(from.year, from.month, from.day),
      to: DateTime(to.year, to.month, to.day),
    );
  }

  // ── Display label for UI ──────────────────────────────────
  String get label {
    switch (type) {
      case ReportPeriodType.today:
        return 'Today';
      case ReportPeriodType.week:
        return 'This Week';
      case ReportPeriodType.month:
        return 'This Month';
      case ReportPeriodType.custom:
        return 'Custom';
      case ReportPeriodType.compare:
        return 'Compare';
    }
  }

  // ── API param formatting (YYYY-MM-DD) ─────────────────────
  String get fromApi => _fmtApi(from);
  String get toApi => _fmtApi(to);

  static String _fmtApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Friendly display (e.g. "Apr 1 – Apr 30, 2025") ────────
  String displayRange() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (from.year == to.year &&
        from.month == to.month &&
        from.day == to.day) {
      return '${months[from.month - 1]} ${from.day}, ${from.year}';
    }
    if (from.year == to.year) {
      return '${months[from.month - 1]} ${from.day} – ${months[to.month - 1]} ${to.day}, ${to.year}';
    }
    return '${months[from.month - 1]} ${from.day}, ${from.year} – ${months[to.month - 1]} ${to.day}, ${to.year}';
  }

  int get dayCount => to.difference(from).inDays + 1;
}