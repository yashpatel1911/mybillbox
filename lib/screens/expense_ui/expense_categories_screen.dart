import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../DBHelper/app_colors.dart';
import '../../DBHelper/app_constant.dart';
import '../../model/expense/expense_category_model.dart';
import '../../provider/expenses_provider/expense_category_provider.dart';

class ExpenseCategoriesScreen extends StatefulWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  State<ExpenseCategoriesScreen> createState() =>
      _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState extends State<ExpenseCategoriesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      context.read<ExpenseCategoryProvider>().getExpenseCategory(
        context,
        search: v.trim().isEmpty ? null : v.trim(),
      );
    });
  }

  // ── Open create/edit bottom sheet ──
  void _openForm({ExpenseCategoryModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.expCatName ?? '');
    final descCtrl = TextEditingController(
      text: existing?.expCatDescription ?? '',
    );
    bool isActive = existing?.isActive ?? true;

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
                  existing == null
                      ? 'Add Expense Category'
                      : 'Edit Expense Category',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Name ──
                const Text(
                  'Category Name *',
                  style: TextStyle(fontSize: 11, color: AppColors.textMedium),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('e.g. Travel, Rent, Food'),
                ),
                const SizedBox(height: 12),

                // ── Description ──
                const Text(
                  'Description (optional)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMedium),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _dec('Notes about this category'),
                ),
                const SizedBox(height: 12),

                // ── Active toggle (edit mode only) ──
                if (existing != null)
                  Row(
                    children: [
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setSheetState(() => isActive = v),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // ── Action buttons ──
                Consumer<ExpenseCategoryProvider>(
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
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    AppConstant.warningMessage(
                                      'Category name is required',
                                      context,
                                    );
                                    return;
                                  }

                                  final ok = existing == null
                                      ? await p.createExpenseCategory(
                                          context,
                                          expCatName: name,
                                          expCatDescription:
                                              descCtrl.text.trim().isEmpty
                                              ? null
                                              : descCtrl.text.trim(),
                                        )
                                      : await p.updateExpenseCategory(
                                          context,
                                          expCatId: existing.expCatId,
                                          expCatName: name,
                                          expCatDescription: descCtrl.text
                                              .trim(),
                                          isActive: isActive,
                                        );

                                  if (!mounted) return;
                                  if (ok) {
                                    Navigator.pop(context);
                                    AppConstant.successMessage(
                                      existing == null
                                          ? 'Category created!'
                                          : 'Category updated!',
                                      context,
                                    );
                                  } else {
                                    AppConstant.errorMessage(
                                      p.errorMessage ?? 'Something went wrong',
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
                                  existing == null ? 'Create' : 'Update',
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
    );
  }

  // ── Confirm delete ──
  void _confirmDelete(ExpenseCategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Category?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${cat.expCatName}"? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final p = context.read<ExpenseCategoryProvider>();
              final ok = await p.deleteExpenseCategory(context, cat.expCatId);
              if (!mounted) return;
              if (ok) {
                AppConstant.successMessage('Category deleted', context);
              } else {
                AppConstant.errorMessage(
                  p.errorMessage ?? 'Failed to delete',
                  context,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
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
          'Expense Categories',
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
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textLight,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearch('');
                          setState(() {});
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
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: Consumer<ExpenseCategoryProvider>(
              builder: (_, p, __) {
                if (p.loadCategory) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  );
                }

                if (p.categoryList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 56,
                          color: AppColors.textLight.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No expense categories yet',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + to add your first category',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => p.getExpenseCategory(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: p.categoryList.length,
                    itemBuilder: (_, i) {
                      final cat = p.categoryList[i];
                      return _CategoryCard(
                        cat: cat,
                        onEdit: () => _openForm(existing: cat),
                        onDelete: () => _confirmDelete(cat),
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

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
    filled: true,
    fillColor: AppColors.pageBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
// _CategoryCard — single row with edit/delete
// ─────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final ExpenseCategoryModel cat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.cat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.category_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // ── Name + description + status ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cat.expCatName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!cat.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (cat.expCatDescription != null &&
                    cat.expCatDescription!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cat.expCatDescription!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // ── Action icons ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconButton(
                icon: Icons.edit_rounded,
                color: AppColors.primary,
                bgColor: AppColors.primary.withOpacity(0.1),
                tooltip: 'Edit',
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                icon: Icons.delete_rounded,
                color: AppColors.red,
                bgColor: AppColors.red.withOpacity(0.1),
                tooltip: 'Delete',
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// _ActionIconButton — styled icon with tap effect
// ─────────────────────────────────────────
class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.color.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      ),
    );
  }
}
