// Overview tab — the headline view of the Reports screen.
// 4 hero cards + trend chart + cash flow strip.

import 'package:flutter/material.dart';
import 'package:mybillbox/screens/reports/stat_card.dart';
import 'package:mybillbox/screens/reports/trend_chart.dart';
import 'package:provider/provider.dart';

import '../../provider/reports_provider.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.summary.revenue.invoiceCount == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: provider.refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _StatsGrid(summary: provider.summary),
              const SizedBox(height: 16),
              TrendChart(data: provider.summary.dailyTrend),
              const SizedBox(height: 16),
              _CashFlowCard(summary: provider.summary),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2x2 grid of hero stat cards
// ─────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final dynamic summary;

  const _StatsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final revenue = summary.revenue;
    final spending = summary.spending;
    final profit = summary.profit;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        StatCard(
          label: 'REVENUE',
          value: 'Rs.${_fmt(revenue.totalInvoiced)}',
          subtitle: '${revenue.invoiceCount} invoices',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        ),
        StatCard(
          label: 'EXPENSES',
          value: 'Rs.${_fmt(spending.totalOutflow)}',
          subtitle: '${spending.purchaseCount + spending.expenseCount} entries',
          icon: Icons.trending_down_rounded,
          color: const Color(0xFFEF4444),
        ),
        StatCard(
          label: profit.isProfit ? 'NET PROFIT' : 'NET LOSS',
          value: 'Rs.${_fmt(profit.netProfit.abs())}',
          subtitle: '${profit.marginPct.toStringAsFixed(1)}% margin',
          icon: profit.isProfit
              ? Icons.savings_rounded
              : Icons.warning_amber_rounded,
          color: profit.isProfit
              ? const Color(0xFF1A3C6E)
              : const Color(0xFFE65100),
        ),
        StatCard(
          label: 'OUTSTANDING',
          value: 'Rs.${_fmt(revenue.totalOutstanding)}',
          subtitle: 'to be collected',
          icon: Icons.schedule_rounded,
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(\d)\b)'),
      (m) => '${m[1]},',
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Cash flow breakdown card (money in / out / net)
// ─────────────────────────────────────────────────────────────
class _CashFlowCard extends StatelessWidget {
  final dynamic summary;

  const _CashFlowCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final profit = summary.profit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Flow',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _flowItem(
                  'Money In',
                  profit.cashIn,
                  Icons.south_west_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _flowItem(
                  'Money Out',
                  profit.cashOut,
                  Icons.north_east_rounded,
                  const Color(0xFFEF4444),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _flowItem(
                  'Net',
                  profit.netProfit,
                  profit.isProfit
                      ? Icons.add_circle_rounded
                      : Icons.remove_circle_rounded,
                  profit.isProfit
                      ? const Color(0xFF1A3C6E)
                      : const Color(0xFFE65100),
                  showSign: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowItem(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool showSign = false,
  }) {
    final prefix = showSign ? (value >= 0 ? '+' : '−') : '';
    final shown = showSign ? value.abs() : value;
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${prefix}Rs.${shown.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)\b)'), (m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load report',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
