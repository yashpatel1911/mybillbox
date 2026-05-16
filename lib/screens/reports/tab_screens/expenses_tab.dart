// Expenses tab — covers both Purchases (stock) and Expenses (operating).
// Lazily fetches via ReportsProvider.fetchExpenses().

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../model/reports/expenses_report_model.dart';
import '../../../provider/reports_provider/reports_provider.dart';


class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        if (provider.isExpensesLoading &&
            provider.expensesReport.overview.totalCount == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.expensesError != null) {
          return _ErrorState(
            message: provider.expensesError!,
            onRetry: provider.fetchExpenses,
          );
        }

        final r = provider.expensesReport;
        return RefreshIndicator(
          onRefresh: provider.fetchExpenses,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewRow(overview: r.overview),
              const SizedBox(height: 14),
              _CategoryDonut(categories: r.categories, total: r.overview.totalSpent),
              const SizedBox(height: 14),
              _SplitCard(split: r.split),
              const SizedBox(height: 14),
              _TopCategoriesCard(
                categories: r.categories,
                total: r.overview.totalSpent,
              ),
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
// 1. Overview — 3 mini cards
// ═════════════════════════════════════════════════════════════
class _OverviewRow extends StatelessWidget {
  final ExpensesOverview overview;
  const _OverviewRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'TOTAL SPENT',
            value: 'Rs.${_fmt(overview.totalSpent)}',
            subtitle: '${overview.totalCount} entries',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'PURCHASES',
            value: 'Rs.${_fmt(overview.purchasesTotal)}',
            subtitle: 'stock bought',
            color: const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: 'EXPENSES',
            value: 'Rs.${_fmt(overview.expensesTotal)}',
            subtitle: 'operating',
            color: const Color(0xFF6366F1),
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
// 2. Donut chart by category
// ═════════════════════════════════════════════════════════════
class _CategoryDonut extends StatefulWidget {
  final List<ExpenseCategoryEntry> categories;
  final double total;
  const _CategoryDonut({required this.categories, required this.total});

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int? _touchedIndex;

  // Color palette for donut segments
  static const _palette = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      title: 'Spending by Category',
      child: widget.categories.isEmpty || widget.total == 0
          ? const _EmptyList(message: 'No spending recorded yet')
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Donut ─────────────────────────────────
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        setState(() {
                          _touchedIndex = (event is FlPanEndEvent ||
                              event is FlTapUpEvent ||
                              resp?.touchedSection == null)
                              ? null
                              : resp!.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: _buildSections(),
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs.${_shortMoney(widget.total)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Legend ────────────────────────────────
          Expanded(
            child: Column(
              children: _buildLegend(),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    // Take top 5 + lump rest into "Other"
    final top = widget.categories.take(5).toList();
    final remaining = widget.categories.skip(5).toList();
    final otherTotal =
    remaining.fold<double>(0, (a, b) => a + b.total);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < top.length; i++) {
      final isTouched = _touchedIndex == i;
      final color = _palette[i % _palette.length];
      sections.add(PieChartSectionData(
        value: top[i].total,
        color: color,
        radius: isTouched ? 22 : 18,
        showTitle: false,
      ));
    }
    if (otherTotal > 0) {
      final isTouched = _touchedIndex == top.length;
      sections.add(PieChartSectionData(
        value: otherTotal,
        color: Colors.grey.shade400,
        radius: isTouched ? 22 : 18,
        showTitle: false,
      ));
    }
    return sections;
  }

  List<Widget> _buildLegend() {
    final top = widget.categories.take(5).toList();
    final remaining = widget.categories.skip(5).toList();
    final otherTotal =
    remaining.fold<double>(0, (a, b) => a + b.total);

    final rows = <Widget>[];
    for (var i = 0; i < top.length; i++) {
      final pct = widget.total > 0 ? (top[i].total / widget.total * 100) : 0;
      rows.add(_legendRow(
        color: _palette[i % _palette.length],
        label: top[i].catName,
        pct: pct.toStringAsFixed(0),
      ));
    }
    if (otherTotal > 0) {
      final pct = widget.total > 0 ? (otherTotal / widget.total * 100) : 0;
      rows.add(_legendRow(
        color: Colors.grey.shade400,
        label: 'Other (${remaining.length})',
        pct: pct.toStringAsFixed(0),
      ));
    }
    return rows;
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required String pct,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 3. Purchase vs Expense split bar
// ═════════════════════════════════════════════════════════════
class _SplitCard extends StatelessWidget {
  final SpendingSplit split;
  const _SplitCard({required this.split});

  @override
  Widget build(BuildContext context) {
    final total = split.purchases + split.expenses;
    if (total == 0) return const SizedBox.shrink();

    return _SectionWrap(
      title: 'Purchases vs Expenses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal split bar
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (split.purchases > 0)
                    Expanded(
                      flex: (split.purchases * 1000).round(),
                      child: Container(color: const Color(0xFFE65100)),
                    ),
                  if (split.expenses > 0)
                    Expanded(
                      flex: (split.expenses * 1000).round(),
                      child: Container(color: const Color(0xFF6366F1)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE65100),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Purchases',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${_fmt(split.purchases)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      '${split.purchasesPct.toStringAsFixed(0)}% of spending',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${_fmt(split.expenses)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      '${split.expensesPct.toStringAsFixed(0)}% of spending',
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
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// 4. Top categories list
// ═════════════════════════════════════════════════════════════
class _TopCategoriesCard extends StatelessWidget {
  final List<ExpenseCategoryEntry> categories;
  final double total;
  const _TopCategoriesCard({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      title: 'Top Categories',
      trailing:
      '${categories.length} ${categories.length == 1 ? "category" : "categories"}',
      child: categories.isEmpty
          ? const _EmptyList(message: 'No categories with spending yet')
          : Column(
        children: categories.asMap().entries.map((e) {
          final cat = e.value;
          final isLast = e.key == categories.length - 1;
          final pct = total > 0 ? (cat.total / total * 100) : 0;
          final color = _categoryColor(cat, e.key);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        cat.isPurchase
                            ? Icons.inventory_2_rounded
                            : Icons.receipt_long_rounded,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.catName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${cat.count} ${cat.count == 1 ? "entry" : "entries"} · ${pct.toStringAsFixed(0)}% of total',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rs.${_fmt(cat.total)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
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

  // Stock Purchase always orange, real categories cycle through palette
  static const _palette = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];

  Color _categoryColor(ExpenseCategoryEntry cat, int index) {
    if (cat.isPurchase) return const Color(0xFFE65100);
    return _palette[index % _palette.length];
  }
}

// ═════════════════════════════════════════════════════════════
// 5. Payment methods
// ═════════════════════════════════════════════════════════════
class _PaymentMethodsCard extends StatelessWidget {
  final List<ExpensePaymentMethodEntry> methods;
  const _PaymentMethodsCard({required this.methods});

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return _SectionWrap(
        title: 'Payment Methods',
        child: const _EmptyList(message: 'No payments recorded'),
      );
    }

    final total = methods.fold<double>(0, (a, b) => a + b.total);

    return _SectionWrap(
      title: 'Payment Methods',
      child: Column(
        children: methods.map((m) {
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
                            'Rs.${_fmt(m.total)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? (m.total / total) : 0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(color),
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
      case 'CASH':
        return const Color(0xFF10B981);
      case 'ONLINE':
        return const Color(0xFF1A3C6E);
      default:
        return Colors.grey;
    }
  }

  static IconData _iconFor(String method) {
    switch (method) {
      case 'CASH':
        return Icons.payments_rounded;
      case 'ONLINE':
        return Icons.phone_iphone_rounded;
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
  const _SectionWrap({
    required this.title,
    required this.child,
    this.trailing,
  });

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
          const SizedBox(height: 12),
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
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Could not load expenses',
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