import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../DBHelper/app_constant.dart';
import '../../../../model/invoice_model.dart';
import '../../../../model/product_model.dart';
import '../../../../provider/invoice_provider.dart';
import '../../../../provider/product_provider.dart';

class InvoiceDetailPageOld extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailPageOld({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailPageOld> createState() => _InvoiceDetailPageOldState();
}

class _InvoiceDetailPageOldState extends State<InvoiceDetailPageOld> {
  InvoiceModel? _invoice;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;

  // ── Customer edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _invoiceDate;

  // ── Items edit state
  final Map<String, _CartItem> _cart = {};
  int _cartCounter = 0;
  final Map<int, String?> _pendingSize = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // ── Discount edit state
  String? _discountType;
  late TextEditingController _discValCtrl;

  // ── Payment edit state
  String _paymentStatus = 'pending';
  final _cashCtrl = TextEditingController(text: '0');
  final _onlineCtrl = TextEditingController(text: '0');
  bool _useCash = false;
  bool _useOnline = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _discValCtrl = TextEditingController(text: '0');
    _invoiceDate = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    _discValCtrl.dispose();
    _cashCtrl.dispose();
    _onlineCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final inv = await context.read<InvoiceProvider>().fetchInvoiceById(
        widget.invoiceId,
      );
      if (mounted && inv != null) {
        setState(() {
          _invoice = inv;
          _loading = false;
          _nameCtrl.text = inv.customerName;
          _mobileCtrl.text = inv.customerMobile;
          _notesCtrl.text = inv.notes;
          _invoiceDate = DateTime.tryParse(inv.invoiceDate) ?? DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterEditMode() {
    final inv = _invoice!;
    _nameCtrl.text = inv.customerName;
    _mobileCtrl.text = inv.customerMobile;
    _notesCtrl.text = inv.notes;
    _invoiceDate = DateTime.tryParse(inv.invoiceDate) ?? DateTime.now();

    _cart.clear();
    _cartCounter = 0;
    _pendingSize.clear();
    for (final item in inv.items) {
      _cartCounter++;
      final key = '${item.productId}_${item.size ?? "none"}_$_cartCounter';
      _cart[key] = _CartItem(
        productId: item.productId,
        productName: item.productName,
        qty: item.quantity,
        unitPrice: item.unitPrice,
        selectedSize: item.size,
        itemDiscount: item.itemDiscount,
      );
    }

    _discountType = inv.discountType;
    _discValCtrl.text = inv.discountValue > 0
        ? inv.discountValue.toStringAsFixed(0)
        : '0';
    _paymentStatus = inv.paymentStatus;
    _useCash = false;
    _useOnline = false;
    _cashCtrl.text = '0';
    _onlineCtrl.text = '0';

    setState(() => _editMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().getProducts(context);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editMode = false;
      _cart.clear();
      _searchQuery = '';
      _searchCtrl.clear();
      _searchDebounce?.cancel();
    });
  }

  double get _subTotal => _cart.values.fold(0, (s, c) => s + c.lineTotal);

  double get _discountAmt {
    final val = double.tryParse(_discValCtrl.text) ?? 0;
    if (_discountType == 'percent') return (_subTotal * val / 100);
    if (_discountType == 'flat') return val.clamp(0, _subTotal);
    return 0;
  }

  double get _editTotal => _subTotal - _discountAmt;

  double get _cashAmount => double.tryParse(_cashCtrl.text) ?? 0;

  double get _onlineAmount => double.tryParse(_onlineCtrl.text) ?? 0;

  double get _totalPaid =>
      (_useCash ? _cashAmount : 0) + (_useOnline ? _onlineAmount : 0);

  List<Map<String, dynamic>> get _paymentsPayload {
    final list = <Map<String, dynamic>>[];
    if (_useCash && _cashAmount > 0)
      list.add({'method': 'cash', 'amount': _cashAmount});
    if (_useOnline && _onlineAmount > 0)
      list.add({'method': 'online', 'amount': _onlineAmount});
    return list;
  }

  void _addToCart(ProductModel product) {
    final prodId = product.prodId!;
    final size = _pendingSize[prodId];
    if (size == null) return;
    setState(() {
      _cartCounter++;
      final key = '${prodId}_${size}_$_cartCounter';
      _cart[key] = _CartItem(
        productId: prodId,
        productName: product.prodName,
        qty: 1,
        unitPrice: product.fixPrice ?? 0,
        selectedSize: size,
        itemDiscount: 0,
      );
    });
  }

  Future<void> _saveEdit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppConstant.warningMessage('Customer name is required', context);
      return;
    }
    if (_mobileCtrl.text.trim().length < 10) {
      AppConstant.warningMessage('Enter a valid mobile number', context);
      return;
    }
    if (_cart.isEmpty) {
      AppConstant.warningMessage('At least one item is required', context);
      return;
    }

    // ── Validate payment amounts ──────────────────
    if (_paymentStatus != 'pending' && (_useCash || _useOnline)) {
      final amountDue = (_editTotal - (_invoice!.amountPaid)).clamp(
        0.0,
        double.infinity,
      );
      if (_totalPaid > amountDue) {
        AppConstant.warningMessage(
          'Payment (₹${_totalPaid.toStringAsFixed(0)}) exceeds remaining due (₹${amountDue.toStringAsFixed(0)})',
          context,
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final items = _cart.values
          .map(
            (c) => {
          'product_id': c.productId,
          'quantity': c.qty,
          'size': c.selectedSize,
          'item_discount': c.itemDiscount,
          'unit_price': c.unitPrice,
        },
      )
          .toList();

      final res = await context.read<InvoiceProvider>().updateInvoice(
        invoiceId: widget.invoiceId,
        customerName: _nameCtrl.text.trim(),
        customerMobile: _mobileCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        invoiceDate: DateFormat('yyyy-MM-dd').format(_invoiceDate),
        items: items,
        discountType: _discountType,
        discountValue: double.tryParse(_discValCtrl.text) ?? 0,
        paymentStatus: _paymentStatus,
        payments: _paymentsPayload,
      );

      if (!mounted) return;
      if (res['status'] == true) {
        AppConstant.successMessage('Invoice updated!', context);
        setState(() {
          _invoice = context.read<InvoiceProvider>().selectedInvoice;
          _editMode = false;
          _cart.clear();
        });
      } else {
        AppConstant.errorMessage(res['message'] ?? 'Failed to update', context);
      }
    } catch (e) {
      AppConstant.errorMessage('Error: $e', context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)\b)'), (m) => '${m[1]},');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: () => _editMode ? _cancelEdit() : Navigator.pop(context),
        ),
        title: Text(
          _editMode ? 'Edit Invoice' : 'Invoice Detail',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (!_loading && _invoice != null && !_invoice!.isCancelled)
            _editMode
                ? TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.red, fontSize: 14),
              ),
            )
                : IconButton(
              onPressed: _enterEditMode,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
          ? _errorState()
          : RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: _editMode ? _buildEditMode() : _buildViewMode(),
        ),
      ),
      bottomNavigationBar: _editMode
          ? Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: _saving ? null : _saveEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            'Save Changes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildViewMode() => Column(
    children: [
      _headerCard(),
      const SizedBox(height: 12),
      _customerCard(),
      const SizedBox(height: 12),
      _itemsCard(),
      const SizedBox(height: 12),
      _summaryCard(),
      const SizedBox(height: 12),
      if (_invoice!.paymentStatus != 'paid') _addPaymentCard(),
    ],
  );

  Widget _buildEditMode() => Column(
    children: [
      _editCustomerCard(),
      const SizedBox(height: 12),
      _editProductsCard(),
      const SizedBox(height: 12),
      _editDiscountCard(),
      const SizedBox(height: 12),
      _editPaymentCard(),
      const SizedBox(height: 12),
      _editSummaryCard(),
      const SizedBox(height: 20),
    ],
  );

  // ─── Edit sections ───────────────────────────────

  Widget _editCustomerCard() => _DetailCard(
    title: 'Customer Details',
    child: Column(
      children: [
        _EditField(
          label: 'Customer Name *',
          controller: _nameCtrl,
          hint: 'e.g. Rajesh Electronics',
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        _EditField(
          label: 'Mobile Number *',
          controller: _mobileCtrl,
          hint: '10-digit mobile number',
          keyboardType: TextInputType.phone,
          maxLength: 10,
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Date *',
              style: TextStyle(fontSize: 11, color: AppColors.textMedium),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _invoiceDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _invoiceDate = d);
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_invoiceDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _EditField(
          label: 'Notes (optional)',
          controller: _notesCtrl,
          hint: 'Any note for this invoice',
          maxLines: 2,
        ),
      ],
    ),
  );

  Widget _editProductsCard() {
    return Consumer<ProductProvider>(
      builder: (ctx, provider, _) {
        return _DetailCard(
          title: 'Products',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 400),
                        () => context.read<ProductProvider>().getProducts(
                      context,
                      search: v.trim().isEmpty ? null : v.trim(),
                    ),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search products to add...',
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
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                      _searchDebounce?.cancel();
                      context.read<ProductProvider>().getProducts(
                        context,
                      );
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  )
                      : null,
                  filled: true,
                  fillColor: AppColors.pageBg,
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
              const SizedBox(height: 10),
              if (provider.loadProduct)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (provider.productList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No products match "$_searchQuery"'
                        : 'No products found',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                  provider.productList.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.productList.length) {
                      WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.read<ProductProvider>().loadMore(),
                      );
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                      );
                    }
                    final p = provider.productList[i];
                    return _EditProductRow(
                      product: p,
                      selectedSize: _pendingSize[p.prodId],
                      addedCount: _cart.entries
                          .where((e) => e.key.startsWith('${p.prodId}_'))
                          .length,
                      onSizeSelected: (size) =>
                          setState(() => _pendingSize[p.prodId!] = size),
                      onAdd: () => _addToCart(p),
                    );
                  },
                ),
              if (_cart.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.border),
                Text(
                  'Selected Items (${_cart.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                ..._cart.entries.map(
                      (entry) => _EditCartRow(
                    item: entry.value,
                    onIncrement: () => setState(() => entry.value.qty++),
                    onDecrement: () => setState(() {
                      if (entry.value.qty > 1) entry.value.qty--;
                    }),
                    onRemove: () => setState(() => _cart.remove(entry.key)),
                    onPriceChanged: (v) => setState(
                          () => entry.value.unitPrice =
                          double.tryParse(v) ?? entry.value.unitPrice,
                    ),
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(
                      '₹${_fmt(_subTotal)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _editDiscountCard() => _DetailCard(
    title: 'Discount (optional)',
    child: Column(
      children: [
        Row(
          children: [
            _DiscBtn(
              label: 'Flat ₹',
              active: _discountType == 'flat',
              onTap: () => setState(() {
                _discountType = 'flat';
                _discValCtrl.text = '0';
              }),
            ),
            const SizedBox(width: 8),
            _DiscBtn(
              label: 'Percent %',
              active: _discountType == 'percent',
              onTap: () => setState(() {
                _discountType = 'percent';
                _discValCtrl.text = '0';
              }),
            ),
            const SizedBox(width: 8),
            _DiscBtn(
              label: 'None',
              active: _discountType == null,
              onTap: () => setState(() {
                _discountType = null;
                _discValCtrl.text = '0';
              }),
            ),
          ],
        ),
        if (_discountType != null) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _discValCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _discountType == 'flat'
                  ? 'Amount in ₹'
                  : 'Percent 0–100',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.pageBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
        ],
      ],
    ),
  );

  Widget _editPaymentCard() => _DetailCard(
    title: 'Payment Status',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_invoice!.amountPaid > 0) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Already paid',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                Text(
                  '₹${_fmt(_invoice!.amountPaid)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _StatusChip(
              label: 'Pending',
              icon: Icons.schedule_rounded,
              color: AppColors.orange,
              selected: _paymentStatus == 'pending',
              onTap: () => setState(() {
                _paymentStatus = 'pending';
                _useCash = false;
                _useOnline = false;
                _cashCtrl.text = '0';
                _onlineCtrl.text = '0';
              }),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'Partial',
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.primary,
              selected: _paymentStatus == 'partial',
              onTap: () => setState(() => _paymentStatus = 'partial'),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'Paid',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.green,
              selected: _paymentStatus == 'paid',
              onTap: () => setState(() {
                _paymentStatus = 'paid';
                _useCash = true;
                _useOnline = false;
                // Only auto-fill the REMAINING due amount, not the full total
                // (existing payments already cover part of the invoice)
                final remaining = (_editTotal - (_invoice?.amountPaid ?? 0))
                    .clamp(0.0, double.infinity);
                _cashCtrl.text = remaining.toStringAsFixed(0);
                _onlineCtrl.text = '0';
              }),
            ),
          ],
        ),
        if (_paymentStatus != 'pending') ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            'Add New Payment',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Enter cash/online for additional payment only',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          _SplitRow(
            icon: Icons.money_rounded,
            label: 'Cash',
            color: AppColors.green,
            isEnabled: _useCash,
            controller: _cashCtrl,
            onToggle: (val) => setState(() {
              _useCash = val;
              if (!val)
                _cashCtrl.text = '0';
              else if (_useOnline) {
                final due = (_editTotal - (_invoice?.amountPaid ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                final rem = due - _cashAmount;
                _onlineCtrl.text = rem > 0 ? rem.toStringAsFixed(0) : '0';
              }
            }),
            onChanged: (v) => setState(() {
              if (_useOnline) {
                final due = (_editTotal - (_invoice?.amountPaid ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                final rem = (due - (double.tryParse(v) ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                _onlineCtrl.text = rem.toStringAsFixed(0);
              }
            }),
          ),
          const SizedBox(height: 8),
          _SplitRow(
            icon: Icons.phone_android_rounded,
            label: 'Online',
            color: AppColors.primary,
            isEnabled: _useOnline,
            controller: _onlineCtrl,
            onToggle: (val) => setState(() {
              _useOnline = val;
              if (!val)
                _onlineCtrl.text = '0';
              else if (_useCash) {
                final due = (_editTotal - (_invoice?.amountPaid ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                final rem = due - _cashAmount;
                _onlineCtrl.text = rem > 0 ? rem.toStringAsFixed(0) : '0';
              }
            }),
            // ✅ FIX: recalculate cash when online amount changes
            onChanged: (v) => setState(() {
              if (_useCash) {
                final due = (_editTotal - (_invoice?.amountPaid ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                final rem = (due - (double.tryParse(v) ?? 0)).clamp(
                  0.0,
                  double.infinity,
                );
                _cashCtrl.text = rem.toStringAsFixed(0);
              }
            }),
          ),
        ],
      ],
    ),
  );

  Widget _editSummaryCard() => _DetailCard(
    title: 'Summary Preview',
    child: Column(
      children: [
        _DetailRow(label: 'Subtotal', value: '₹${_fmt(_subTotal)}'),
        if (_discountType != null && _discountAmt > 0)
          _DetailRow(
            label: 'Discount',
            value: '− ₹${_fmt(_discountAmt)}',
            valueColor: AppColors.red,
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.border),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '₹${_fmt(_editTotal)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        if (_useCash || _useOnline) ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: 'New Payment',
            value: '₹${_fmt(_totalPaid)}',
            valueColor: AppColors.green,
          ),
        ],
      ],
    ),
  );

  // ─── View sections ───────────────────────────────

  Widget _headerCard() {
    final inv = _invoice!;
    final c = _statusColor(inv.paymentStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                inv.customerName[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  inv.invoiceDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(inv.paymentStatus),
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (inv.isCancelled) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cancelled',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerCard() {
    final inv = _invoice!;
    return _DetailCard(
      title: 'Customer Details',
      child: Column(
        children: [
          _DetailRow(label: 'Name', value: inv.customerName),
          _DetailRow(label: 'Mobile', value: inv.customerMobile),
          _DetailRow(
            label: 'Date',
            value: DateFormat(
              'dd MMM yyyy',
            ).format(DateTime.tryParse(inv.invoiceDate) ?? DateTime.now()),
          ),
          if (inv.notes.isNotEmpty)
            _DetailRow(label: 'Notes', value: inv.notes),
        ],
      ),
    );
  }

  Widget _itemsCard() {
    final inv = _invoice!;
    return _DetailCard(
      title: 'Items (${inv.items.length})',
      child: Column(
        children: inv.items
            .map(
              (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      item.productName[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        [
                          if (item.size != null && item.size!.isNotEmpty)
                            'Size: ${item.size}',
                          '× ${item.quantity}  ·  ₹${_fmt(item.unitPrice)} each',
                        ].join('   '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      if (item.itemDiscount > 0)
                        Text(
                          'Discount: ₹${_fmt(item.itemDiscount)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${_fmt(item.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _summaryCard() {
    final inv = _invoice!;
    return _DetailCard(
      title: 'Payment Summary',
      child: Column(
        children: [
          _DetailRow(label: 'Subtotal', value: '₹${_fmt(inv.subTotal)}'),
          if (inv.discountType != null && inv.discountAmount > 0)
            _DetailRow(
              label:
              'Discount (${inv.discountType == 'percent' ? '${inv.discountValue.toStringAsFixed(0)}%' : 'flat'})',
              value: '− ₹${_fmt(inv.discountAmount)}',
              valueColor: AppColors.red,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '₹${_fmt(inv.totalAmount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Amount Paid',
            value: '₹${_fmt(inv.amountPaid)}',
            valueColor: AppColors.green,
          ),
          _DetailRow(
            label: 'Amount Due',
            value: '₹${_fmt(inv.amountDue)}',
            valueColor: inv.amountDue > 0 ? AppColors.red : AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _addPaymentCard() {
    final cashCtrl = TextEditingController();
    final onlineCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocal) {
        bool useCash = false, useOnline = false, paying = false;
        return StatefulBuilder(
          builder: (context, setInner) {
            double cashAmt = double.tryParse(cashCtrl.text) ?? 0;
            double onlineAmt = double.tryParse(onlineCtrl.text) ?? 0;
            double totalPaid =
                (useCash ? cashAmt : 0) + (useOnline ? onlineAmt : 0);
            double amountDue = _invoice!.amountDue;

            List<Map<String, dynamic>> buildPayments() {
              final list = <Map<String, dynamic>>[];
              if (useCash && cashAmt > 0)
                list.add({'method': 'cash', 'amount': cashAmt});
              if (useOnline && onlineAmt > 0)
                list.add({'method': 'online', 'amount': onlineAmt});
              return list;
            }

            return _DetailCard(
              title: 'Record Payment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                      Text(
                        'Due: ₹${_fmt(amountDue)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select one or both — enter amounts freely',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 12),
                  _SplitRow(
                    icon: Icons.money_rounded,
                    label: 'Cash',
                    color: AppColors.green,
                    isEnabled: useCash,
                    controller: cashCtrl,
                    onToggle: (val) => setInner(() {
                      useCash = val;
                      if (!val) cashCtrl.text = '';
                    }),
                    onChanged: (_) => setInner(() {}),
                  ),
                  const SizedBox(height: 10),
                  _SplitRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Online',
                    color: AppColors.primary,
                    isEnabled: useOnline,
                    controller: onlineCtrl,
                    onToggle: (val) => setInner(() {
                      useOnline = val;
                      if (!val) onlineCtrl.text = '';
                    }),
                    onChanged: (_) => setInner(() {}),
                  ),
                  if (useCash || useOnline) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (useCash)
                            _PayRow(
                              label: 'Cash',
                              value: '₹${_fmt(cashAmt)}',
                              color: AppColors.green,
                            ),
                          if (useOnline)
                            _PayRow(
                              label: 'Online',
                              value: '₹${_fmt(onlineAmt)}',
                              color: AppColors.primary,
                            ),
                          const Divider(height: 12, color: AppColors.border),
                          _PayRow(
                            label: 'Total Paying',
                            value: '₹${_fmt(totalPaid)}',
                            color: AppColors.textDark,
                            bold: true,
                          ),
                          _PayRow(
                            label: 'Remaining After',
                            value: (amountDue - totalPaid) > 0
                                ? '₹${_fmt(amountDue - totalPaid)}'
                                : 'Fully Paid',
                            color: (amountDue - totalPaid) > 0
                                ? AppColors.orange
                                : AppColors.green,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: paying
                          ? null
                          : () async {
                        if (!useCash && !useOnline) {
                          AppConstant.warningMessage(
                            'Select at least one payment method',
                            context,
                          );
                          return;
                        }
                        if (totalPaid <= 0) {
                          AppConstant.warningMessage(
                            'Enter a valid amount',
                            context,
                          );
                          return;
                        }
                        if (totalPaid > amountDue) {
                          AppConstant.warningMessage(
                            'Total paid exceeds due amount',
                            context,
                          );
                          return;
                        }
                        setInner(() => paying = true);
                        try {
                          final res = await context
                              .read<InvoiceProvider>()
                              .addPayment(
                            invoiceId: widget.invoiceId,
                            payments: buildPayments(),
                            paymentDate: DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now()),
                          );
                          if (!mounted) return;
                          if (res['status'] == true) {
                            AppConstant.successMessage(
                              'Payment recorded!',
                              context,
                            );
                            cashCtrl.clear();
                            onlineCtrl.clear();
                            await _load();
                          } else {
                            AppConstant.errorMessage(
                              res['message'] ?? 'Failed',
                              context,
                            );
                          }
                        } catch (e) {
                          AppConstant.errorMessage('Error: $e', context);
                        } finally {
                          setInner(() => paying = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: paying
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Record Payment',
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
            );
          },
        );
      },
    );
  }

  Widget _errorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        const Text(
          'Invoice not found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _load,
          child: const Text(
            'Retry',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

// ─── Cart item model for edit ────────────────────────
class _CartItem {
  final int productId;
  final String productName;
  int qty;
  double unitPrice;
  String? selectedSize;
  double itemDiscount;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    this.selectedSize,
    this.itemDiscount = 0,
  });

  double get lineTotal => (unitPrice * qty) - itemDiscount;
}

// ─── Edit product row ────────────────────────────────
class _EditProductRow extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final int addedCount;
  final ValueChanged<String?> onSizeSelected;
  final VoidCallback onAdd;

  const _EditProductRow({
    required this.product,
    required this.selectedSize,
    required this.addedCount,
    required this.onSizeSelected,
    required this.onAdd,
  });

  List<String> get _sizes {
    if (product.isFreeSize) return ['Free Size'];
    final raw = product.sizes ?? '';
    if (raw.trim().isEmpty) return ['Free Size'];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: addedCount > 0 ? AppColors.green : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.prodName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '₹${product.fixPrice?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (addedCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$addedCount added',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: selectedSize != null ? onAdd : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedSize != null
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selectedSize != null
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: selectedSize != null
                        ? AppColors.primary
                        : AppColors.textLight.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Size *',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sizes.map((s) {
                      final sel = selectedSize == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onSizeSelected(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          if (selectedSize == null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '↑ Select a size to add',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.orange.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Edit cart row ───────────────────────────────────
class _EditCartRow extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onIncrement, onDecrement, onRemove;
  final ValueChanged<String> onPriceChanged;

  const _EditCartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.selectedSize != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          item.selectedSize!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price (₹)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 34,
                      child: TextFormField(
                        initialValue: item.unitPrice.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        onChanged: onPriceChanged,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          filled: true,
                          fillColor: AppColors.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Qty',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _QtyBtn(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      _QtyBtn(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${item.lineTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ────────────────────────────
class _SplitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;

  const _SplitRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isEnabled ? color.withOpacity(0.05) : AppColors.pageBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isEnabled ? color : AppColors.border,
        width: isEnabled ? 1.5 : 1,
      ),
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => onToggle(!isEnabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isEnabled ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isEnabled ? color : AppColors.border,
                width: 1.5,
              ),
            ),
            child: isEnabled
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: isEnabled ? color : AppColors.textLight),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isEnabled ? color : AppColors.textMedium,
          ),
        ),
        const Spacer(),
        if (isEnabled)
          SizedBox(
            width: 110,
            height: 36,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: color.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
          )
        else
          Text(
            'Tap to enable',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    ),
  );
}

class _PayRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;

  const _PayRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EditField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final int maxLines;
  final int? maxLength;

  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          filled: true,
          fillColor: AppColors.pageBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
    ],
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 14, color: AppColors.textDark),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.textLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DiscBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DiscBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.pageBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textMedium,
            ),
          ),
        ),
      ),
    ),
  );
}