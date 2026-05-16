// Revenue vs Expenses line chart.
// Uses fl_chart — add `fl_chart: ^0.68.0` to pubspec.yaml first.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../model/reports/report_summary_model.dart';

class TrendChart extends StatelessWidget {
  final List<DailyTrendPoint> data;
  final Color revenueColor;
  final Color expensesColor;

  const TrendChart({
    super.key,
    required this.data,
    this.revenueColor = const Color(0xFF10B981),
    this.expensesColor = const Color(0xFFEF4444),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No data for this period',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    // Find max for y-axis scaling
    final maxY = data
        .map((p) => p.revenue > p.expenses ? p.revenue : p.expenses)
        .fold<double>(0, (a, b) => a > b ? a : b);

    // Round up to a nice number for grid lines
    final yMax = maxY == 0 ? 1000.0 : _niceMax(maxY);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + legend ────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue vs Expenses',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    _legendDot(revenueColor, 'Revenue'),
                    const SizedBox(width: 10),
                    _legendDot(expensesColor, 'Expenses'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Chart ─────────────────────────────────────────
          AspectRatio(
            aspectRatio: 1.6,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: yMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _shortMoney(value),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _xInterval(data.length).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox();
                        final d = data[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (spots) => spots.map((s) {
                      final i = s.x.toInt();
                      final d = data[i].date;
                      final isRevenue = s.barIndex == 0;
                      return LineTooltipItem(
                        '${isRevenue ? "Revenue" : "Expenses"}\n'
                        '${d.day}/${d.month}: Rs.${s.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isRevenue ? revenueColor : expensesColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  // Revenue line
                  _buildLine(
                    data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                        .toList(),
                    revenueColor,
                  ),
                  // Expenses line
                  _buildLine(
                    data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.expenses))
                        .toList(),
                    expensesColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    // Only render dots when:
    //  - range is small enough that dots aren't crowded (≤31 days), AND
    //  - the specific value is > 0 (skip zero-value dots which clutter the chart)
    final showDots = spots.length <= 31;

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: showDots,
        checkToShowDot: (spot, _) => spot.y > 0,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 1.5,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  String _shortMoney(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  double _niceMax(double v) {
    final mag = _orderOfMagnitude(v);
    final m = (v / mag).ceil() * mag;
    return m.toDouble();
  }

  double _orderOfMagnitude(double v) {
    if (v <= 100) return 50;
    if (v <= 1000) return 100;
    if (v <= 10000) return 1000;
    if (v <= 100000) return 10000;
    if (v <= 1000000) return 100000;
    return 1000000;
  }

  int _xInterval(int len) {
    if (len <= 7) return 1;
    if (len <= 14) return 2;
    if (len <= 31) return 5;
    if (len <= 90) return 10;
    return (len / 8).ceil();
  }
}
