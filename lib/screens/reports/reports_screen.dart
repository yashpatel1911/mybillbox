// Main Reports screen — top-level container.
// Owns the period picker and the 4 tab placeholders. The other 3 tabs
// (Sales / Expenses / P&L) are stubbed and will be built in Phase 2+.

import 'package:flutter/material.dart';
import 'package:mybillbox/screens/reports/period_picker.dart';
import 'package:mybillbox/screens/reports/report_overview_tab.dart';
import 'package:provider/provider.dart';

import '../../provider/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ReportsProvider();
    // Fetch the default period (this month) on first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.fetch());
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            bottom: const TabBar(
              labelColor: Color(0xFF1A3C6E),
              unselectedLabelColor: Color(0xFF888888),
              indicatorColor: Color(0xFF1A3C6E),
              indicatorWeight: 2.5,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Sales'),
                Tab(text: 'Expenses'),
                Tab(text: 'P&L'),
              ],
            ),
          ),
          body: Column(
            children: [
              Consumer<ReportsProvider>(
                builder: (ctx, p, _) =>
                    PeriodPicker(current: p.period, onChanged: p.setPeriod),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    OverviewTab(),
                    _ComingSoonTab(label: 'Sales'),
                    _ComingSoonTab(label: 'Expenses'),
                    _ComingSoonTab(label: 'P&L'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;

  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '$label tab',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Coming in next phase',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
