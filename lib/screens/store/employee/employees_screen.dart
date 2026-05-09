import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../model/employee_model.dart';
import '../../../provider/employee_provider.dart';

// ──────────────────────────────────────────────────
// EMPLOYEES SCREEN
// ──────────────────────────────────────────────────
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Role-based color mapping
  static const _roleColors = {
    'ADMIN': AppColors.red,
    'MANAGER': AppColors.orange,
    'EMPLOYEE': AppColors.primary,
  };

  Color _colorForRole(String role) =>
      _roleColors[role.toUpperCase()] ?? AppColors.primary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().getEmployees(context);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EmployeeModel> _filterEmployees(List<EmployeeModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.username.toLowerCase().contains(q) ||
              e.contactNo.toLowerCase().contains(q) ||
              (e.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── ADD ───────────────────────────────────────────
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(
        onSubmit:
            ({
              required String name,
              required String username,
              required String contactNo,
              String? email,
              String? password,
              required String role,
              required bool isActive,
            }) async {
              final ok = await context.read<EmployeeProvider>().addEmployee(
                context,
                name: name,
                username: username,
                contactNo: contactNo,
                email: email,
                password: password!,
                role: role,
              );
              if (!mounted) return false;
              if (ok) {
                _showSnack('Employee added successfully');
              } else {
                _showSnack(
                  context.read<EmployeeProvider>().errorMessage ??
                      'Failed to add',
                  error: true,
                );
              }
              return ok;
            },
      ),
    );
  }

  // ── EDIT ──────────────────────────────────────────
  void _openEditSheet(EmployeeModel emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(
        employee: emp,
        onSubmit:
            ({
              required String name,
              required String username,
              required String contactNo,
              String? email,
              String? password,
              required String role,
              required bool isActive,
            }) async {
              final ok = await context.read<EmployeeProvider>().updateEmployee(
                context,
                empId: emp.id,
                name: name,
                contactNo: contactNo,
                email: email,
                role: role,
                isActive: isActive,
              );
              if (!mounted) return false;
              if (ok) {
                _showSnack('Employee updated successfully');
              } else {
                _showSnack(
                  context.read<EmployeeProvider>().errorMessage ??
                      'Failed to update',
                  error: true,
                );
              }
              return ok;
            },
      ),
    );
  }

  // ── DELETE ────────────────────────────────────────
  Future<void> _confirmDelete(EmployeeModel emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Employee?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${emp.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<EmployeeProvider>().deleteEmployee(
      context,
      emp.id,
    );
    if (!mounted) return;
    if (ok) {
      _showSnack('Employee deleted');
    } else {
      _showSnack(
        context.read<EmployeeProvider>().errorMessage ?? 'Failed to delete',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Employees',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<EmployeeProvider>(
            builder: (_, p, __) {
              if (p.employeeList.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${p.employeeList.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textLight,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, _) {
                if (provider.loadEmployee) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (provider.errorMessage != null &&
                    provider.employeeList.isEmpty) {
                  return _ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.getEmployees(context),
                  );
                }

                final filtered = _filterEmployees(provider.employeeList);

                if (filtered.isEmpty) {
                  return _EmptyView(searchQuery: _searchQuery);
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.getEmployees(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final emp = filtered[i];
                      return _EmployeeCard(
                        employee: emp,
                        color: _colorForRole(emp.role),
                        onEdit: () => _openEditSheet(emp),
                        onDelete: () => _confirmDelete(emp),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'person',
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text(
          'Add Employee',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// EMPLOYEE CARD (REDESIGNED)
// ──────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initial = employee.name.isNotEmpty
        ? employee.name[0].toUpperCase()
        : '?';
    final hasEmail = employee.email != null && employee.email!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.20), color.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              // Active status dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: employee.isActive ? AppColors.green : AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBg, width: 2.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Main content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + role
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        employee.role,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Username
                Text(
                  '@${employee.username}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Contact (phone always; email if exists)
                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 12,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      employee.contactNo,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (hasEmail) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_rounded,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          employee.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action menu (icon buttons only) ──
          const SizedBox(width: 6),
          Column(
            children: [
              _ActionIconButton(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: onEdit,
                tooltip: 'Edit',
              ),
              const SizedBox(height: 6),
              _ActionIconButton(
                icon: Icons.delete_outline_rounded,
                color: AppColors.red,
                onTap: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// COMPACT ACTION ICON BUTTON
// ──────────────────────────────────────────────────
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// ADD / EDIT FORM (BOTTOM SHEET)
// ──────────────────────────────────────────────────
typedef _SubmitCallback =
    Future<bool> Function({
      required String name,
      required String username,
      required String contactNo,
      String? email,
      String? password,
      required String role,
      required bool isActive,
    });

class _EmployeeFormSheet extends StatefulWidget {
  final EmployeeModel? employee;
  final _SubmitCallback onSubmit;

  const _EmployeeFormSheet({this.employee, required this.onSubmit});

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  // Focus nodes for next-field auto-focus
  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late String _role;
  late bool _isActive;
  bool _obscurePwd = true;
  bool _submitting = false;

  static const _roles = ['EMPLOYEE', 'MANAGER', 'ADMIN'];

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _usernameCtrl = TextEditingController(text: e?.username ?? '');
    _contactCtrl = TextEditingController(text: e?.contactNo ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _passwordCtrl = TextEditingController();
    _role = e?.role ?? 'EMPLOYEE';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _contactFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final ok = await widget.onSubmit(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      contactNo: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      password: _isEdit ? null : _passwordCtrl.text,
      role: _role,
      isActive: _isActive,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with icon
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEdit
                              ? Icons.edit_rounded
                              : Icons.person_add_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit Employee' : 'Add Employee',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEdit
                                ? 'Update employee details'
                                : 'Fill in the details below',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Name ──
                  _FormField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    icon: Icons.person_rounded,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _isEdit
                        ? _contactFocus.requestFocus()
                        : _usernameFocus.requestFocus(),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),

                  // ── Username ──
                  _FormField(
                    label: 'Username',
                    controller: _usernameCtrl,
                    focusNode: _usernameFocus,
                    icon: Icons.alternate_email_rounded,
                    enabled: !_isEdit,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contactFocus.requestFocus(),
                    validator: (v) {
                      if (_isEdit) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (v.trim().length < 3) return 'Min 3 characters';
                      return null;
                    },
                  ),

                  // ── Contact (max 10 digits) ──
                  _FormField(
                    label: 'Mobile Number',
                    controller: _contactCtrl,
                    focusNode: _contactFocus,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (v.trim().length != 10) {
                        return 'Mobile number must be 10 digits';
                      }
                      return null;
                    },
                  ),

                  // ── Email ──
                  _FormField(
                    label: 'Email (optional)',
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _isEdit
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onSubmitted: (_) {
                      if (_isEdit) {
                        _submit();
                      } else {
                        _passwordFocus.requestFocus();
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final ok = RegExp(
                        r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$',
                      ).hasMatch(v.trim());
                      return ok ? null : 'Invalid email';
                    },
                  ),

                  // ── Password (add only) ──
                  if (!_isEdit)
                    _FormField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      icon: Icons.lock_rounded,
                      obscureText: _obscurePwd,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePwd
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),

                  // ── Role selector (segmented buttons) ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(2, 4, 0, 8),
                    child: Text(
                      'Role',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: _roles.map((r) {
                      final selected = _role == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = r),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: r != _roles.last ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.pageBg,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              r,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // ── Active toggle (edit only) ──
                  if (_isEdit) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  (_isActive ? AppColors.green : AppColors.red)
                                      .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.block_rounded,
                              size: 18,
                              color: _isActive
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Status',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Inactive employees cannot log in',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: AppColors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 4),

                  // ── Action buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Update' : 'Add Employee',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// REUSABLE FORM FIELD
// ──────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.focusNode,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? AppColors.textDark : AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
              suffixIcon: suffix,
              filled: true,
              fillColor: enabled
                  ? AppColors.pageBg
                  : AppColors.pageBg.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// ERROR / EMPTY VIEWS
// ──────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.red,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String searchQuery;

  const _EmptyView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchQuery.isEmpty
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No employees yet' : 'No matches found',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searchQuery.isEmpty
                ? 'Tap "Add Employee" to get started'
                : 'No results for "$searchQuery"',
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
