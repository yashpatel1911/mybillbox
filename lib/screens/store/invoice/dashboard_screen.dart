import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:mybillbox/DBHelper/session_manager.dart';
import 'package:mybillbox/screens/store/invoice/invoice_details/invoice_detail_page.dart';
import 'package:mybillbox/screens/store/invoice/invoice_details/invoice_pdf_generator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../DBHelper/app_constant.dart';
import '../../../model/invoice_details/invoice_model.dart';
import '../../../model/invoice_details/dashboard_stats_model.dart';
import '../../../provider/invoice_provider.dart';
import 'create_invoice/create_invoice_page.dart';
import 'invoice_details/pdf_screens/pdf_design_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  bool _showToday = true;

  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _quickMonth;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final p = context.read<InvoiceProvider>();
      _showToday ? p.loadMoreToday() : p.loadMoreAll();
    }
  }

  Future<void> _loadAll() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final p = context.read<InvoiceProvider>();
      await Future.wait([p.fetchInvoices(), p.fetchDashboardStats()]);
    });
  }

  Map<String, String?> get _filterParams {
    String? dateFrom, dateTo;
    if (_quickMonth != null) {
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

  void _applyFilters() {
    if (!mounted) return;
    final p = _filterParams;
    final provider = context.read<InvoiceProvider>();
    Future.wait([
      provider.fetchInvoices(
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

  Future<void> _goToCreateInvoice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInvoicePage()),
    );
    if (mounted) _applyFilters();
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
    _applyFilters();
  }

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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌤';
    if (h < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  Color _statusColor(String s) {
    switch (s) {
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

  String _statusLabel(String s) {
    switch (s) {
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

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_invoice',
        onPressed: _goToCreateInvoice,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Consumer<InvoiceProvider>(
          builder: (ctx, provider, _) {
            final stats = _showToday
                ? provider.statsWrapper.today
                : provider.statsWrapper.allTime;
            final invoices = _showToday
                ? provider.todayInvoices
                : provider.allInvoices;
            final listItems = _showToday ? invoices.take(4).toList() : invoices;

            return RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  // ── Pinned App Bar ──────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.cardBg,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    toolbarHeight: 60,
                    flexibleSpace: _appBarContent(),
                  ),

                  // ── Stats (scrolls away) ────────────────────────
                  SliverToBoxAdapter(
                    child: _statsPanel(stats, provider.statsLoading),
                  ),

                  // ── Filter (All Time only, scrolls away) ────────
                  if (!_showToday)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: _filterSection(),
                      ),
                    ),

                  // ── Sticky "Invoices" header ─────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HeaderDelegate(
                      child: _invoiceListHeader(listItems.length),
                    ),
                  ),

                  // ── Invoice cards ───────────────────────────────
                  if (provider.isLoading)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _skeletonCard(),
                        childCount: 4,
                      ),
                    )
                  else if (listItems.isEmpty)
                    SliverToBoxAdapter(child: _emptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _invoiceCard(listItems[i]),
                        ),
                        childCount: listItems.length,
                      ),
                    ),

                  // ── Footer ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (provider.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        if (!provider.isLoading &&
                            !provider.isLoadingMore &&
                            listItems.isNotEmpty)
                          Builder(
                            builder: (_) {
                              final noMore = _showToday
                                  ? !provider.hasMoreToday
                                  : !provider.hasMoreAll;
                              return noMore
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 1,
                                            color: AppColors.border,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'All invoices loaded',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 30,
                                            height: 1,
                                            color: AppColors.border,
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        const SizedBox(height: 100),
                      ],
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

  // ═══════════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _appBarContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${SessionManager().name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Today / All Time toggle
            Container(
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.pageBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _togglePill('Today', _showToday),
                  _togglePill('All Time', !_showToday),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Notification button
            /*Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textMedium,
                    size: 19,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _togglePill(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showToday = label == 'Today'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS PANEL
  // ═══════════════════════════════════════════════════════════════
  Widget _statsPanel(DashboardStatsModel stats, bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          // Row 1 — Total Billed | Collected
          Row(
            children: [
              _statCard(
                label: 'Total Billed',
                value: '₹${_fmt(stats.totalBilled)}',
                sub: '${stats.totalInvoices} invoices',
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary,
                loading: loading,
              ),
              const SizedBox(width: 10),
              _statCard(
                label: 'Collected',
                value: '₹${_fmt(stats.totalCollected)}',
                sub: '${stats.paidCount} paid',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.green,
                loading: loading,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2 — Outstanding | Overdue
          Row(
            children: [
              _statCard(
                label: 'Outstanding',
                value: '₹${_fmt(stats.outstanding)}',
                sub: '${stats.unpaidCount} unpaid',
                icon: Icons.schedule_rounded,
                color: AppColors.orange,
                loading: loading,
              ),
              const SizedBox(width: 10),
              _statCard(
                label: 'Overdue',
                value: '₹${_fmt(stats.overdueAmount)}',
                sub: '${stats.overdueCount} overdue',
                icon: Icons.warning_amber_rounded,
                color: AppColors.red,
                loading: loading,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 3 — Cash | Online | Credit
          Row(
            children: [
              _methodCard(
                label: 'Cash',
                value: '₹${_fmt(stats.cashCollected)}',
                icon: Icons.money_rounded,
                color: AppColors.green,
                loading: loading,
              ),
              const SizedBox(width: 8),
              _methodCard(
                label: 'Online',
                value: '₹${_fmt(stats.onlineCollected)}',
                icon: Icons.phone_android_rounded,
                color: AppColors.primary,
                loading: loading,
              ),
              const SizedBox(width: 8),
              _methodCard(
                label: 'Credit',
                value: '₹${_fmt(stats.creditApplied)}',
                icon: Icons.account_balance_rounded,
                color: AppColors.orange,
                loading: loading,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 4 — Refunds banner
          _refundBanner(stats, loading),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required bool loading,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.028),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  loading
                      ? _shimmer(width: 58, height: 13)
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: color, size: 12),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            loading
                ? _shimmer(width: 48, height: 12)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _refundBanner(DashboardStatsModel stats, bool loading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.undo_rounded,
              color: AppColors.red,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refunds Issued',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Amount returned to customers',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          loading
              ? _shimmer(width: 56, height: 14)
              : Text(
                  '₹${_fmt(stats.refundsAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INVOICE LIST STICKY HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _invoiceListHeader(int count) {
    return Container(
      color: AppColors.pageBg,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Text(
            _showToday ? "Today's Invoices" : 'All Invoices',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const Spacer(),
          if (_hasActiveFilter)
            GestureDetector(
              onTap: _clearFilters,
              child: const Row(
                children: [
                  Icon(Icons.close_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 3),
                  Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FILTER SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _filterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 500),
                      _applyFilters,
                    );
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search name, invoice no...',
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
                    contentPadding: EdgeInsets.zero,
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
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                width: 42,
                height: 42,
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
                  size: 19,
                  color: _hasActiveFilter ? Colors.white : AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                  '${_dateFrom != null ? DateFormat('dd MMM').format(_dateFrom!) : '...'} → ${_dateTo != null ? DateFormat('dd MMM').format(_dateTo!) : '...'}',
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
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _monthChip(String label, String? key) {
    final active = _quickMonth == key;
    return GestureDetector(
      onTap: () {
        setState(() => _quickMonth = key);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

  // ═══════════════════════════════════════════════════════════════
  //  INVOICE CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _invoiceCard(InvoiceModel inv) {
    final c = _statusColor(inv.paymentStatus);
    return GestureDetector(
      onTap: () => Get.to(InvoiceDetailPage(invoiceId: inv.invoiceId)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inv.hasUnresolvedOverpayment
                ? AppColors.orange.withOpacity(0.45)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + invoice no
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.customerName,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          inv.invoiceNumber,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount + badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_fmt(inv.totalAmount)}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overpayment strip
            if (inv.hasUnresolvedOverpayment)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(13, 9, 13, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Overpaid ₹${_fmt(inv.overpaidAmount)} — tap to resolve',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Footer: date + action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 9, 10, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    inv.invoiceDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: AppColors.primary,
                    onTap: () =>
                        Get.to(InvoiceDetailPage(invoiceId: inv.invoiceId)),
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    color: AppColors.orange,
                    onTap: () async {
                      final p = context.read<InvoiceProvider>();
                      final full = await p.fetchInvoiceById(inv.invoiceId);
                      if (full != null && context.mounted) {
                        PdfDesignSelector.show(context, full); // ← new
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    color: AppColors.red,
                    onTap: () => _confirmCancel(inv),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_hasActiveFilter ? AppColors.orange : AppColors.primary)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _hasActiveFilter
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_outlined,
                size: 26,
                color: _hasActiveFilter ? AppColors.orange : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _hasActiveFilter ? 'No results found' : 'No invoices yet',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _hasActiveFilter
                  ? 'Try adjusting your filters'
                  : 'Tap + to create your first invoice',
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SKELETON
  // ═══════════════════════════════════════════════════════════════
  Widget _skeletonCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(width: 110, height: 11),
                  const SizedBox(height: 6),
                  _shimmer(width: 70, height: 9),
                ],
              ),
            ),
            const SizedBox(width: 13),
          ],
        ),
      ),
    );
  }

  Widget _shimmer({required double width, required double height}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FILTER SHEET
  // ═══════════════════════════════════════════════════════════════
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
                    'Filter Invoices',
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
                runSpacing: 8,
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
                    setState(() {
                      _filterStatus = tempStatus;
                      _dateFrom = tempFrom;
                      _dateTo = tempTo;
                      _quickMonth = null;
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

  // ═══════════════════════════════════════════════════════════════
  //  CONFIRM CANCEL
  // ═══════════════════════════════════════════════════════════════
  void _confirmCancel(InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Invoice',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Cancel ${inv.invoiceNumber} for ${inv.customerName}?\nThis cannot be undone.',
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
                final res = await context.read<InvoiceProvider>().cancelInvoice(
                  inv.invoiceId,
                );
                if (mounted) {
                  if (res['status'] == true) {
                    AppConstant.successMessage(
                      'Invoice cancelled successfully',
                      context,
                    );
                    _applyFilters();
                  } else {
                    AppConstant.errorMessage(
                      res['message'] ?? 'Failed to cancel',
                      context,
                    );
                  }
                }
              } catch (e) {
                if (mounted) AppConstant.errorMessage('Error: $e', context);
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
              'Cancel Invoice',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SLIVER PERSISTENT HEADER DELEGATE
// ═══════════════════════════════════════════════════════════════
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _HeaderDelegate({required this.child});

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    // Clamp height so layoutExtent never exceeds paintExtent
    final double height = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => old.child != child;
}

// ═══════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════════
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
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
