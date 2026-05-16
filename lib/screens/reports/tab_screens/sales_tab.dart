// Sales tab — drives by ReportsProvider.salesReport.
// Lazily fetches when first opened.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../model/reports/sales_report_model.dart';
import '../../../provider/reports_provider/reports_provider.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Fetch on first build (lazy — only when Sales tab is opened)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        if (provider.isSalesLoading &&
            provider.salesReport.overview.invoiceCount == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.salesError != null) {
          return _ErrorState(
            message: provider.salesError!,
            onRetry: provider.fetchSales,
          );
        }

        final r = provider.salesReport;
        return RefreshIndicator(
          onRefresh: provider.fetchSales,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewRow(overview: r.overview),
              const SizedBox(height: 14),
              _DailySalesChart(data: r.dailyRevenue),
              const SizedBox(height: 14),
              _TopProductsCard(products: r.topProducts),
              const SizedBox(height: 14),
              _TopCustomersCard(customers: r.topCustomers),
              const SizedBox(height: 14),
              _PaymentMethodsCard(methods: r.paymentMethods),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 1. Overview — 3 mini cards (Invoiced / Collected / Pending)
// ═════════════════════════════════════════════════════════════
class _OverviewRow extends StatelessWidget {
  final SalesOverview overview;

  const _OverviewRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    final collectionRate = overview.totalInvoiced > 0
        ? (overview.totalCollected / overview.totalInvoiced * 100)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'INVOICED',
            value: 'Rs.${_fmt(overview.totalInvoiced)}',
            subtitle: '${overview.invoiceCount} bills',
            color: const Color(0xFF1A3C6E),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'COLLECTED',
            value: 'Rs.${_fmt(overview.totalCollected)}',
            subtitle: '${collectionRate.toStringAsFixed(0)}% rate',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'PENDING',
            value: 'Rs.${_fmt(overview.totalPending)}',
            subtitle: 'to collect',
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 2. Daily Sales — bar chart
// ═════════════════════════════════════════════════════════════
class _DailySalesChart extends StatelessWidget {
  final List<DailyRevenuePoint> data;

  const _DailySalesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _SectionWrap(title: 'Daily Sales', child: _EmptyChart());
    }

    final maxY = data
        .map((p) => p.revenue)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 1000.0 : _niceMax(maxY);

    return _SectionWrap(
      title: 'Daily Sales',
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            maxY: yMax,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItem: (group, _, rod, __) {
                  final i = group.x;
                  final d = data[i].date;
                  return BarTooltipItem(
                    '${d.day}/${d.month}\nRs.${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yMax / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
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
                  reservedSize: 38,
                  interval: yMax / 4,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _shortMoney(v),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final step = _xInterval(data.length);
                    final lastIndex = data.length - 1;

                    // Show label if:
                    //  - it's at a step boundary (0, step, 2*step, ...), OR
                    //  - it's the very last index AND far enough from the
                    //    previous step marker to avoid visual overlap
                    final isStep = i % step == 0;
                    final distFromLastStep = lastIndex % step;
                    final isLastAndSafe =
                        i == lastIndex && distFromLastStep > step ~/ 2;

                    if (!isStep && !isLastAndSafe) return const SizedBox();

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
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.revenue,
                    color: const Color(0xFF10B981),
                    width: data.length <= 31 ? 6 : 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 3. Top Products
// ═════════════════════════════════════════════════════════════
class _TopProductsCard extends StatelessWidget {
  final List<TopProduct> products;

  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      title: 'Top Products',
      trailing: '${products.length} ${products.length == 1 ? "item" : "items"}',
      child: products.isEmpty
          ? const _EmptyList(message: 'No products sold yet')
          : Column(
              children: products.asMap().entries.map((e) {
                final isLast = e.key == products.length - 1;
                return Column(
                  children: [
                    _RankRow(
                      rank: e.key + 1,
                      title: e.value.productName,
                      subtitle:
                          '${e.value.qtySold} ${e.value.qtySold == 1 ? "sold" : "sold"}',
                      trailing: 'Rs.${_fmt(e.value.revenue)}',
                      trailingColor: const Color(0xFF10B981),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade100,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _RankRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _rankColors(rank);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.$2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: trailingColor,
            ),
          ),
        ],
      ),
    );
  }

  // Gold / Silver / Bronze for top 3, grey for rest
  static (Color, Color) _rankColors(int rank) {
    switch (rank) {
      case 1:
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706)); // gold
      case 2:
        return (const Color(0xFFE5E7EB), const Color(0xFF6B7280)); // silver
      case 3:
        return (const Color(0xFFFEF7CD), const Color(0xFFA16207)); // bronze
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF9CA3AF));
    }
  }
}

// ═════════════════════════════════════════════════════════════
// 4. Top Customers — with avatar initials
// ═════════════════════════════════════════════════════════════
class _TopCustomersCard extends StatelessWidget {
  final List<TopCustomer> customers;

  const _TopCustomersCard({required this.customers});

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      title: 'Top Customers',
      trailing:
          '${customers.length} ${customers.length == 1 ? "customer" : "customers"}',
      child: customers.isEmpty
          ? const _EmptyList(message: 'No customer data yet')
          : Column(
              children: customers.asMap().entries.map((e) {
                final c = e.value;
                final isLast = e.key == customers.length - 1;
                final avatarColor = _avatarColor(c.customerName);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: avatarColor.$1,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(c.customerName),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: avatarColor.$2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.customerName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${c.customerMobile} · ${c.invoiceCount} ${c.invoiceCount == 1 ? "bill" : "bills"}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rs.${_fmt(c.totalSpent)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A3C6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade100,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '—';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Deterministic color per name — palette of 6
  static (Color, Color) _avatarColor(String name) {
    const palette = [
      (Color(0xFFDBEAFE), Color(0xFF1A3C6E)),
      (Color(0xFFDCFCE7), Color(0xFF166534)),
      (Color(0xFFFEE2E2), Color(0xFF991B1B)),
      (Color(0xFFFEF3C7), Color(0xFF92400E)),
      (Color(0xFFE0E7FF), Color(0xFF3730A3)),
      (Color(0xFFFCE7F3), Color(0xFF9D174D)),
    ];
    final h = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[h % palette.length];
  }
}

// ═════════════════════════════════════════════════════════════
// 5. Payment methods — horizontal bars
// ═════════════════════════════════════════════════════════════
class _PaymentMethodsCard extends StatelessWidget {
  final List<PaymentMethodEntry> methods;

  const _PaymentMethodsCard({required this.methods});

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return _SectionWrap(
        title: 'Payment Methods',
        child: const _EmptyList(message: 'No payments recorded'),
      );
    }

    // For percentages, use sum of POSITIVE amounts (refunds are shown
    // separately as a negative entry, not in the percentage base).
    final positiveTotal = methods
        .where((m) => m.total > 0)
        .fold<double>(0, (a, b) => a + b.total);

    return _SectionWrap(
      title: 'Payment Methods',
      child: Column(
        children: methods.map((m) {
          final isNegative = m.total < 0;
          final pct = (positiveTotal > 0 && !isNegative)
              ? (m.total / positiveTotal * 100).clamp(0, 100)
              : 0;
          final color = _colorFor(m.method);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(m.method), size: 13, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.displayLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${isNegative ? "−" : ""}Rs.${_fmt(m.total.abs())}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (!isNegative)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: positiveTotal > 0
                                ? (m.total / positiveTotal)
                                : 0,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        )
                      else
                        Text(
                          '${m.count} refund${m.count == 1 ? "" : "s"}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Color _colorFor(String method) {
    switch (method) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'online':
        return const Color(0xFF1A3C6E);
      case 'credit':
        return const Color(0xFFE65100);
      case 'refund':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  static IconData _iconFor(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments_rounded;
      case 'online':
        return Icons.phone_iphone_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'refund':
        return Icons.undo_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}

// ═════════════════════════════════════════════════════════════
// Shared helpers
// ═════════════════════════════════════════════════════════════
class _SectionWrap extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _SectionWrap({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String message;

  const _EmptyList({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'No data for this period',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

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
              'Could not load sales',
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

// ── Formatters ─────────────────────────────────────────────
String _fmt(double v) {
  final s = v.toStringAsFixed(0);
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(\d)\b)'),
    (m) => '${m[1]},',
  );
}

String _shortMoney(double v) {
  if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

double _niceMax(double v) {
  final mag = _orderOfMagnitude(v);
  return ((v / mag).ceil() * mag).toDouble();
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
  if (len <= 31) return 7; // weekly markers for a month
  if (len <= 90) return 10;
  return (len / 8).ceil();
}
