class DashboardStatsModel {
  final double totalBilled;
  final double totalCollected;
  final double outstanding;     // pending + partial + overdue due
  final double overdueAmount;   // only overdue invoices due (replaces totalDue)
  final int    totalInvoices;
  final int    paidCount;
  final int    pendingCount;
  final int    partialCount;
  final int    overdueCount;
  final int    unpaidCount;
  final double pendingAmount;
  final double partialAmount;
  final double cashCollected;
  final double onlineCollected;

  const DashboardStatsModel({
    required this.totalBilled,
    required this.totalCollected,
    required this.outstanding,
    required this.overdueAmount,
    required this.totalInvoices,
    required this.paidCount,
    required this.pendingCount,
    required this.partialCount,
    required this.overdueCount,
    required this.unpaidCount,
    required this.pendingAmount,
    required this.partialAmount,
    required this.cashCollected,
    required this.onlineCollected,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
    int _i(dynamic v) =>
        v == null ? 0 : int.tryParse(v.toString()) ?? 0;

    return DashboardStatsModel(
      totalBilled:     _d(json['total_billed']),
      totalCollected:  _d(json['total_collected']),
      outstanding:     _d(json['outstanding']),
      overdueAmount:   _d(json['overdue_amount']),   // replaces total_due
      totalInvoices:   _i(json['total_invoices']),
      paidCount:       _i(json['paid_count']),
      pendingCount:    _i(json['pending_count']),
      partialCount:    _i(json['partial_count']),
      overdueCount:    _i(json['overdue_count']),
      unpaidCount:     _i(json['unpaid_count']),
      pendingAmount:   _d(json['pending_amount']),
      partialAmount:   _d(json['partial_amount']),
      cashCollected:   _d(json['cash_collected']),
      onlineCollected: _d(json['online_collected']),
    );
  }

  // ── Empty/zero state for initial load ──
  factory DashboardStatsModel.empty() => const DashboardStatsModel(
    totalBilled:     0,
    totalCollected:  0,
    outstanding:     0,
    overdueAmount:   0,
    totalInvoices:   0,
    paidCount:       0,
    pendingCount:    0,
    partialCount:    0,
    overdueCount:    0,
    unpaidCount:     0,
    pendingAmount:   0,
    partialAmount:   0,
    cashCollected:   0,
    onlineCollected: 0,
  );
}

// ── Wrapper holding both today + all_time stats ──
class DashboardStatsWrapper {
  final DashboardStatsModel today;
  final DashboardStatsModel allTime;

  const DashboardStatsWrapper({
    required this.today,
    required this.allTime,
  });

  factory DashboardStatsWrapper.fromJson(Map<String, dynamic> json) {
    return DashboardStatsWrapper(
      today:   DashboardStatsModel.fromJson(
          json['today'] as Map<String, dynamic>),
      allTime: DashboardStatsModel.fromJson(
          json['all_time'] as Map<String, dynamic>),
    );
  }

  factory DashboardStatsWrapper.empty() => DashboardStatsWrapper(
    today:   DashboardStatsModel.empty(),
    allTime: DashboardStatsModel.empty(),
  );
}