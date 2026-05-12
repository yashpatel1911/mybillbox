import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../DBHelper/app_colors.dart';
import '../../DBHelper/app_constant.dart';
import '../../model/expense/expense_model.dart';
import '../../model/expense/expense_category_model.dart';
import '../../provider/expenses_provider/expense_provider.dart';
import '../../provider/expenses_provider/expense_category_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _filter = 'overall'; // 'today' | 'overall'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().getExpenses(context, filter: _filter);
      // load categories for the form dropdown
      context.read<ExpenseCategoryProvider>().getExpenseCategory(context);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ExpenseProvider>().getExpenses(
        context,
        filter: _filter,
        search: v.trim().isEmpty ? null : v.trim(),
      );
    });
  }

  void _switchFilter(String f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    context.read<ExpenseProvider>().getExpenses(
      context,
      filter: f,
      search: _searchCtrl.text.trim().isEmpty
          ? null
          : _searchCtrl.text.trim(),
    );
  }

  // ── Create/Edit form ──
  void _openForm({ExpenseModel? existing}) {
    final partyCtrl =
    TextEditingController(text: existing?.partyName ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.tryParse(existing.paidOn) ?? DateTime.now()
        : DateTime.now();
    String paymentMethod = existing?.paymentMethod ?? 'CASH';
    int? selectedCatId = existing?.expCatId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle ──
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing == null ? 'Add Expense' : 'Edit Expense',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Party Name ──
                  _label('Party Name (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: partyCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('e.g. ABC Suppliers'),
                  ),
                  const SizedBox(height: 12),

                  // ── Category dropdown ──
                  _label('Expense Category *'),
                  const SizedBox(height: 6),
                  Consumer<ExpenseCategoryProvider>(
                    builder: (_, cp, __) {
                      final activeCats = cp.categoryList
                          .where((c) => c.isActive)
                          .toList();
                      return Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.pageBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedCatId,
                            hint: const Text(
                              'Select category',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                              ),
                            ),
                            items: activeCats
                                .map((c) => DropdownMenuItem<int>(
                              value: c.expCatId,
                              child: Text(
                                c.expCatName,
                                style: const TextStyle(
                                    fontSize: 13),
                              ),
                            ))
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => selectedCatId = v),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Amount ──
                  _label('Amount *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _dec('0.00'),
                  ),
                  const SizedBox(height: 12),

                  // ── Date picker ──
                  _label('Paid On *'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: AppColors.textMedium),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Payment method ──
                  _label('Payment Method *'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _paymentChip(
                          label: 'Cash',
                          icon: Icons.payments_rounded,
                          selected: paymentMethod == 'CASH',
                          onTap: () => setSheetState(
                                  () => paymentMethod = 'CASH'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _paymentChip(
                          label: 'Online',
                          icon: Icons.account_balance_rounded,
                          selected: paymentMethod == 'ONLINE',
                          onTap: () => setSheetState(
                                  () => paymentMethod = 'ONLINE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Notes ──
                  _label('Notes (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: _dec('Any additional info'),
                  ),
                  const SizedBox(height: 16),

                  // ── Action buttons ──
                  Consumer<ExpenseProvider>(
                    builder: (_, p, __) => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: p.isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: p.isSubmitting
                                ? null
                                : () async {
                              // ── Validations ──
                              if (selectedCatId == null) {
                                AppConstant.warningMessage(
                                    'Select a category', context);
                                return;
                              }
                              final amt = double.tryParse(
                                  amountCtrl.text.trim());
                              if (amt == null || amt <= 0) {
                                AppConstant.warningMessage(
                                    'Enter a valid amount',
                                    context);
                                return;
                              }

                              final paidOnStr = DateFormat(
                                  'yyyy-MM-dd')
                                  .format(selectedDate);

                              final ok = existing == null
                                  ? await p.createExpense(
                                context,
                                partyName: partyCtrl.text
                                    .trim()
                                    .isEmpty
                                    ? null
                                    : partyCtrl.text.trim(),
                                expCatId: selectedCatId!,
                                amount: amt,
                                paidOn: paidOnStr,
                                paymentMethod: paymentMethod,
                                notes: notesCtrl.text
                                    .trim()
                                    .isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                              )
                                  : await p.updateExpense(
                                context,
                                expId: existing.expId,
                                partyName:
                                partyCtrl.text.trim(),
                                expCatId: selectedCatId!,
                                amount: amt,
                                paidOn: paidOnStr,
                                paymentMethod: paymentMethod,
                                notes: notesCtrl.text.trim(),
                              );

                              if (!mounted) return;
                              if (ok) {
                                Navigator.pop(context);
                                AppConstant.successMessage(
                                  existing == null
                                      ? 'Expense added!'
                                      : 'Expense updated!',
                                  context,
                                );
                              } else {
                                AppConstant.errorMessage(
                                  p.errorMessage ??
                                      'Something went wrong',
                                  context,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: p.isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              existing == null ? 'Save' : 'Update',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Expense?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this expense of ₹${exp.amount.toStringAsFixed(2)}? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMedium)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final p = context.read<ExpenseProvider>();
              final ok = await p.deleteExpense(context, exp.expId);
              if (!mounted) return;
              if (ok) {
                AppConstant.successMessage('Expense deleted', context);
              } else {
                AppConstant.errorMessage(
                    p.errorMessage ?? 'Failed to delete', context);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Filter tabs (Today / Overall) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: _filterTab('Today', 'today')),
                const SizedBox(width: 8),
                Expanded(
                    child: _filterTab('Overall', 'overall')),
              ],
            ),
          ),

          // ── Summary card ──
          Consumer<ExpenseProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryItem(
                        'Total',
                        '₹${p.summary.totalAmount.toStringAsFixed(2)}',
                        AppColors.primary,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border),
                    Expanded(
                      child: _summaryItem(
                        'Cash',
                        '₹${p.summary.cashTotal.toStringAsFixed(2)}',
                        AppColors.textDark,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border),
                    Expanded(
                      child: _summaryItem(
                        'Online',
                        '₹${p.summary.onlineTotal.toStringAsFixed(2)}',
                        AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by party name...',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textLight),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _onSearch('');
                    setState(() {});
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textLight),
                )
                    : null,
                filled: true,
                fillColor: AppColors.cardBg,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (_, p, __) {
                if (p.loadExpenses) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  );
                }

                if (p.expenseList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 56,
                          color: AppColors.textLight.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'today'
                              ? 'No expenses today'
                              : 'No expenses yet',
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + to add your first expense',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => p.getExpenses(context, filter: _filter),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: p.expenseList.length,
                    itemBuilder: (_, i) {
                      final exp = p.expenseList[i];
                      return _ExpenseCard(
                        exp: exp,
                        onEdit: () => _openForm(existing: exp),
                        onDelete: () => _confirmDelete(exp),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── small reusable UI bits ──
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
  );

  Widget _filterTab(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => _switchFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMedium)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _paymentChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color:
                selected ? AppColors.primary : AppColors.textMedium),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                selected ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle:
    const TextStyle(color: AppColors.textLight, fontSize: 13),
    filled: true,
    fillColor: AppColors.pageBg,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
  );
}

// ─────────────────────────────────────────
// _ExpenseCard
// ─────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  final ExpenseModel exp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.exp,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = exp.paymentMethod == 'CASH';
    final dateStr = exp.paidOn.isNotEmpty
        ? DateFormat('dd MMM yyyy')
        .format(DateTime.tryParse(exp.paidOn) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              // Title block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.partyName?.isNotEmpty == true
                          ? exp.partyName!
                          : (exp.expCatName ?? 'Expense'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exp.expCatName ?? '-'} • $dateStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '₹${exp.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Payment method chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCash
                      ? Colors.green.withOpacity(0.12)
                      : Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCash
                          ? Icons.payments_rounded
                          : Icons.account_balance_rounded,
                      size: 11,
                      color: isCash ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCash ? 'Cash' : 'Online',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isCash ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              if (exp.notes?.isNotEmpty == true) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exp.notes!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              // Action buttons
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      size: 14, color: AppColors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}