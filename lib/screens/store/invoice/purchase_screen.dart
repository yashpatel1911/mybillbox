import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:mybillbox/DBHelper/session_manager.dart';
import 'package:mybillbox/model/purchase_details/purchase_model.dart';
import 'package:mybillbox/provider/purchase_provider.dart';
import 'package:mybillbox/screens/purchase_ui/create_purchase_page.dart';
import 'package:mybillbox/screens/purchase_ui/purchase_details/purchase_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../DBHelper/app_colors.dart';
import '../../../DBHelper/app_constant.dart';
import '../../../model/purchase_details/purchase_dashboard_stats_model.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  bool _showToday = true;

  // ── Scroll Controller ─────────────────────────
  final _scrollCtrl = ScrollController();

  // ── Filter State ──────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _quickMonth;

  // ── Debounce for search ───────────────────────
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _scrollCtrl.addListener(_onScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Infinite Scroll Trigger ───────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final provider = context.read<PurchaseProvider>();
      if (_showToday) {
        provider.loadMoreToday();
      } else {
        provider.loadMoreAll();
      }
    }
  }

  // ── Initial load (no filters) ─────────────────
  Future<void> _loadAll() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<PurchaseProvider>();
      await Future.wait([
        provider.fetchPurchases(),
        provider.fetchDashboardStats(),
      ]);
    });
  }

  // ── Convert active filter state → API params ──
  Map<String, String?> get _filterParams {
    String? dateFrom;
    String? dateTo;

    if (_quickMonth != null) {
      // Convert "yyyy-MM" → first and last day of that month
      final parts = _quickMonth!.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      dateFrom = DateFormat('yyyy-MM-dd').format(DateTime(y, m, 1));
      dateTo = DateFormat('yyyy-MM-dd').format(DateTime(y, m + 1, 0));
    } else {
      dateFrom = _dateFrom != null
          ? DateFormat('yyyy-MM-dd').format(_dateFrom!)
          : null;
      dateTo = _dateTo != null
          ? DateFormat('yyyy-MM-dd').format(_dateTo!)
          : null;
    }

    return {
      'search': _searchQuery.isNotEmpty ? _searchQuery : null,
      'paymentStatus': _filterStatus,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };
  }

  // ── Apply all active filters via backend ──────
  void _applyFilters() {
    if (!mounted) return;
    final p = _filterParams;
    final provider = context.read<PurchaseProvider>();

    Future.wait([
      provider.fetchPurchases(
        search: p['search'],
        paymentStatus: p['paymentStatus'],
        dateFrom: p['dateFrom'],
        dateTo: p['dateTo'],
      ),
      provider.fetchDashboardStats(
        search: p['search'],
        paymentStatus: p['paymentStatus'],
        dateFrom: p['dateFrom'],
        dateTo: p['dateTo'],
      ),
    ]);
  }

  Future<void> _goToCreatePurchase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePurchasePage()),
    );
    if (mounted) {
      // Refresh with active filters preserved
      _applyFilters();
    }
  }

  bool get _hasActiveFilter =>
      _searchQuery.isNotEmpty ||
      _filterStatus != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _quickMonth != null;

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = null;
      _dateFrom = null;
      _dateTo = null;
      _quickMonth = null;
      _searchCtrl.clear();
    });
    _applyFilters(); // fetch unfiltered data from backend
  }

  // ── Quick months (last 6) ─────────────────────
  List<Map<String, String>> get _quickMonths {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return {
        'key': DateFormat('yyyy-MM').format(d),
        'label': DateFormat('MMM yy').format(d),
      };
    });
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)\b)'), (m) => '${m[1]},');

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.green;
      case 'partial':
        return AppColors.primary;
      case 'overdue':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_purchase',
        onPressed: _goToCreatePurchase,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Consumer<PurchaseProvider>(
          builder: (ctx, provider, _) {
            // ── Server already filtered both lists ──
            final purchasesToShow = _showToday
                ? provider.todayPurchases
                : provider.allPurchase;

            return RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  _appBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Toggle ──────────────────
                          _toggleBar(),
                          const SizedBox(height: 16),

                          // ── Stat Cards ───────────────
                          _statCards(
                            _showToday
                                ? provider.statsWrapper.today
                                : provider.statsWrapper.allTime,
                            provider.statsLoading,
                          ),
                          const SizedBox(height: 16),

                          // ── Cash / Online Row ─────────
                          _paymentMethodRow(
                            _showToday
                                ? provider.statsWrapper.today
                                : provider.statsWrapper.allTime,
                            provider.statsLoading,
                          ),
                          const SizedBox(height: 22),

                          // ── Filter Section (All Time only) ──
                          if (!_showToday) ...[
                            _filterSection(),
                            const SizedBox(height: 14),
                          ],

                          _recentHeader(purchasesToShow.length),
                          const SizedBox(height: 12),

                          // ── Purchase List ──────────────
                          provider.isLoading
                              ? _loadingState()
                              : _recentPurchases(purchasesToShow),

                          // ── Load More Spinner ─────────
                          if (provider.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),

                          // ── End of list indicator ─────
                          if (!provider.isLoading && !provider.isLoadingMore)
                            Builder(
                              builder: (_) {
                                final noMore = _showToday
                                    ? !provider.hasMoreToday
                                    : !provider.hasMoreAll;
                                final hasItems = purchasesToShow.isNotEmpty;
                                if (noMore && hasItems) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'All Purchases loaded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────
  SliverAppBar _appBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Purchase',
        style: const TextStyle(
          color: AppColors.textMedium,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _topBtn(IconData icon, {bool badge = false}) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textMedium, size: 20),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // ── Toggle Bar ────────────────────────────────
  Widget _toggleBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _toggleBtn('Today', _showToday),
          _toggleBtn('All Time', !_showToday),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showToday = label == 'Today'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Section ────────────────────────────
  Widget _filterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  // Debounce: wait 500ms after user stops typing
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _applyFilters();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, purchase no...',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _searchCtrl.clear();
                            });
                            _debounce?.cancel();
                            _applyFilters();
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasActiveFilter
                      ? AppColors.primary
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasActiveFilter
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _hasActiveFilter ? Colors.white : AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Quick Month Chips ──────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _monthChip('All', null),
              const SizedBox(width: 6),
              ..._quickMonths.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _monthChip(m['label']!, m['key']),
                ),
              ),
            ],
          ),
        ),

        if (_filterStatus != null || _dateFrom != null || _dateTo != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              if (_filterStatus != null)
                _activeChip(
                  _statusLabel(_filterStatus!),
                  _statusColor(_filterStatus!),
                  () {
                    setState(() => _filterStatus = null);
                    _applyFilters();
                  },
                ),
              if (_dateFrom != null || _dateTo != null)
                _activeChip(
                  '${_dateFrom != null ? DateFormat('dd MMM').format(_dateFrom!) : '...'}'
                  ' → '
                  '${_dateTo != null ? DateFormat('dd MMM').format(_dateTo!) : '...'}',
                  AppColors.primary,
                  () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                    _applyFilters();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _monthChip(String label, String? key) {
    final active = _quickMonth == key;
    return GestureDetector(
      onTap: () {
        setState(() => _quickMonth = key);
        _applyFilters(); // trigger backend fetch with new month range
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _activeChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  // ── Filter Bottom Sheet ───────────────────────
  void _showFilterSheet() {
    String? tempStatus = _filterStatus;
    DateTime? tempFrom = _dateFrom;
    DateTime? tempTo = _dateTo;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Purchases',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setModal(() {
                      tempStatus = null;
                      tempFrom = null;
                      tempTo = null;
                    }),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Payment Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['paid', 'partial', 'pending', 'overdue']
                    .map(
                      (s) => GestureDetector(
                        onTap: () => setModal(
                          () => tempStatus = tempStatus == s ? null : s,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: tempStatus == s
                                ? _statusColor(s).withOpacity(0.12)
                                : AppColors.pageBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tempStatus == s
                                  ? _statusColor(s)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _statusLabel(s),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tempStatus == s
                                  ? _statusColor(s)
                                  : AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      label: 'From',
                      date: tempFrom,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: tempFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setModal(() => tempFrom = d);
                      },
                      onClear: () => setModal(() => tempFrom = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateTile(
                      label: 'To',
                      date: tempTo,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: tempTo ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setModal(() => tempTo = d);
                      },
                      onClear: () => setModal(() => tempTo = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    // ── Apply to state then hit backend ──
                    setState(() {
                      _filterStatus = tempStatus;
                      _dateFrom = tempFrom;
                      _dateTo = tempTo;
                      _quickMonth =
                          null; // clear quick month when custom range set
                    });
                    Navigator.pop(ctx);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('dd MMM yy').format(date) : label,
              style: TextStyle(
                fontSize: 13,
                color: date != null ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            date != null
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                  )
                : const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textLight,
                  ),
          ],
        ),
      ),
    );
  }

  // ── Stat Cards ────────────────────────────────
  Widget _statCards(PurchaseDashboardStatsModel stats, bool loading) {
    final cards = [
      {
        'label': 'Total Billed',
        'value': '₹${_fmt(stats.totalBilled)}',
        'icon': Icons.account_balance_wallet_outlined,
        'color': AppColors.primary,
        'sub': '${stats.totalPurchases} Purchases',
      },
      {
        'label': 'Collected',
        'value': '₹${_fmt(stats.totalCollected)}',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.green,
        'sub': '${stats.paidCount} Paid',
      },
      {
        'label': 'Outstanding',
        'value': '₹${_fmt(stats.outstanding)}',
        'icon': Icons.schedule_rounded,
        'color': AppColors.orange,
        'sub': '${stats.unpaidCount} Unpaid',
      },
      {
        'label': 'Overdue',
        'value': '₹${_fmt(stats.overdueAmount)}',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.red,
        'sub': '${stats.overdueCount} Overdue',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((s) {
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s['label'] as String,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s['icon'] as IconData, color: color, size: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  loading
                      ? Container(
                          height: 14,
                          width: 70,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          s['value'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  Text(
                    s['sub'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Cash / Online Row ─────────────────────────
  Widget _paymentMethodRow(PurchaseDashboardStatsModel stats, bool loading) {
    return Row(
      children: [
        _methodCard(
          label: 'Cash',
          value: '₹${_fmt(stats.cashCollected)}',
          icon: Icons.money_rounded,
          color: AppColors.green,
          loading: loading,
        ),
        const SizedBox(width: 12),
        _methodCard(
          label: 'Online',
          value: '₹${_fmt(stats.onlineCollected)}',
          icon: Icons.phone_android_rounded,
          color: AppColors.primary,
          loading: loading,
        ),
      ],
    );
  }

  Widget _methodCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool loading,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                loading
                    ? Container(
                        height: 12,
                        width: 55,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Header ─────────────────────────────
  Widget _recentHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _showToday ? 'Today\'s Purchases' : 'All Purchases',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  // ── Loading Skeleton ──────────────────────────
  Widget _loadingState() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ── Purchase List ──────────────────────────────
  Widget _recentPurchases(List<PurchaseModel> purchases) {
    // Today: still cap at 4 visible | All Time: show all loaded pages
    final list = _showToday ? purchases.take(4).toList() : purchases;

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hasActiveFilter
                    ? AppColors.orange.withOpacity(0.08)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _hasActiveFilter
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_outlined,
                size: 28,
                color: _hasActiveFilter ? AppColors.orange : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilter ? 'No results found' : 'No purchasess yet',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hasActiveFilter
                  ? 'Try changing your filters'
                  : 'Tap + to create your first purchases',
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: list.map((inv) {
        final c = _statusColor(inv.paymentStatus);
        return GestureDetector(
          onTap: () => Get.to(PurchaseDetailPage(purchaseId: inv.purchaseId)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // ── Top: avatar + name + amount + status ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    children: [
                      // ── Circle avatar ──
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.withOpacity(0.12),
                        ),
                        child: Center(
                          child: Text(
                            inv.customerName[0].toUpperCase(),
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ── Name + purchases no ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.customerName,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inv.purchaseNumber,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ── Amount + status ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_fmt(inv.totalAmount)}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: c.withOpacity(0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _statusLabel(inv.paymentStatus),
                              style: TextStyle(
                                color: c,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Bottom: date + action buttons ─────
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Date
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        inv.purchaseDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      // Edit
                      _PurchasesActionBtn(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: AppColors.primary,
                        bgColor: AppColors.primary,
                        onTap: () => Get.to(
                          PurchaseDetailPage(purchaseId: inv.purchaseId),
                        ),
                      ),
                      const SizedBox(width: 6),

                      const SizedBox(width: 6),
                      // Cancel
                      _PurchasesActionBtn(
                        icon: Icons.delete_outline_outlined,
                        label: 'Delete',
                        color: AppColors.red,
                        bgColor: AppColors.red,
                        onTap: () => _confirmCancel(inv),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Confirm Cancel Dialog ─────────────────────
  void _confirmCancel(PurchaseModel inv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Purchase',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Cancel ${inv.purchaseNumber} for ${inv.customerName}?\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await context
                    .read<PurchaseProvider>()
                    .cancelPurchase(inv.purchaseId);
                if (mounted) {
                  if (res['status'] == true) {
                    AppConstant.successMessage(
                      'Purchase cancelled successfully',
                      context,
                    );
                    // Refresh with active filters preserved
                    _applyFilters();
                  } else {
                    AppConstant.errorMessage(
                      res['message'] ?? 'Failed to cancel',
                      context,
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  AppConstant.errorMessage('Error: $e', context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel Purchase',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Purchases Action Button ────────────────────────────────
class _PurchasesActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _PurchasesActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: bgColor.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Option Tile ───────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color == AppColors.red ? AppColors.red : AppColors.textDark,
      ),
    ),
    subtitle: Text(
      sub,
      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
    ),
  );
}
