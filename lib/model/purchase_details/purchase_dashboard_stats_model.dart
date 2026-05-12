class PurchaseDashboardStatsModel {
  final double totalBilled;
  final double totalCollected;
  final double outstanding; // pending + partial + overdue due
  final double overdueAmount; // only overdue purchases due (replaces totalDue)
  final int totalPurchases;
  final int paidCount;
  final int pendingCount;
  final int partialCount;
  final int overdueCount;
  final int unpaidCount;
  final double pendingAmount;
  final double partialAmount;
  final double cashCollected;
  final double onlineCollected;

  const PurchaseDashboardStatsModel({
    required this.totalBilled,
    required this.totalCollected,
    required this.outstanding,
    required this.overdueAmount,
    required this.totalPurchases,
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

  factory PurchaseDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
    int _i(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;

    return PurchaseDashboardStatsModel(
      totalBilled: _d(json['total_billed']),
      totalCollected: _d(json['total_collected']),
      outstanding: _d(json['outstanding']),
      overdueAmount: _d(json['overdue_amount']),
      // replaces total_due
      totalPurchases: _i(json['total_purchases']),
      paidCount: _i(json['paid_count']),
      pendingCount: _i(json['pending_count']),
      partialCount: _i(json['partial_count']),
      overdueCount: _i(json['overdue_count']),
      unpaidCount: _i(json['unpaid_count']),
      pendingAmount: _d(json['pending_amount']),
      partialAmount: _d(json['partial_amount']),
      cashCollected: _d(json['cash_collected']),
      onlineCollected: _d(json['online_collected']),
    );
  }

  // ── Empty/zero state for initial load ──
  factory PurchaseDashboardStatsModel.empty() =>
      const PurchaseDashboardStatsModel(
        totalBilled: 0,
        totalCollected: 0,
        outstanding: 0,
        overdueAmount: 0,
        totalPurchases: 0,
        paidCount: 0,
        pendingCount: 0,
        partialCount: 0,
        overdueCount: 0,
        unpaidCount: 0,
        pendingAmount: 0,
        partialAmount: 0,
        cashCollected: 0,
        onlineCollected: 0,
      );
}

// ── Wrapper holding both today + all_time stats ──
class PurchaseDashboardStatsWrapper {
  final PurchaseDashboardStatsModel today;
  final PurchaseDashboardStatsModel allTime;

  const PurchaseDashboardStatsWrapper({
    required this.today,
    required this.allTime,
  });

  factory PurchaseDashboardStatsWrapper.fromJson(Map<String, dynamic> json) {
    return PurchaseDashboardStatsWrapper(
      today: PurchaseDashboardStatsModel.fromJson(
        json['today'] as Map<String, dynamic>,
      ),
      allTime: PurchaseDashboardStatsModel.fromJson(
        json['all_time'] as Map<String, dynamic>,
      ),
    );
  }

  factory PurchaseDashboardStatsWrapper.empty() =>
      PurchaseDashboardStatsWrapper(
        today: PurchaseDashboardStatsModel.empty(),
        allTime: PurchaseDashboardStatsModel.empty(),
      );
}
