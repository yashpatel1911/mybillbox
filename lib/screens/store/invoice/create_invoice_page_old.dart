import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../DBHelper/app_constant.dart';
import '../../../model/invoice_details/customer_model.dart';
import '../../../model/product_model.dart';
import '../../../provider/invoice_provider.dart';
import '../../../provider/product_provider.dart';

class CreateInvoicePageOld extends StatefulWidget {
  const CreateInvoicePageOld({super.key});

  @override
  State<CreateInvoicePageOld> createState() => _CreateInvoicePageOldState();
}

class _CreateInvoicePageOldState extends State<CreateInvoicePageOld> {
  int _step = 1;
  bool _submitting = false;

  // Step 1
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();

  // Customer lookup state
  Timer? _mobileDebounce;
  CustomerModel? _lookedUpCustomer;
  bool _customerLookupLoading = false;

  // Step 2
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Map<String, _CartItem> _cart = {};
  final Map<int, String?> _pendingSize = {};
  Timer? _searchDebounce;
  int _cartCounter = 0;

  // Step 3
  String? _discountType;
  final _discValCtrl = TextEditingController(text: '0');
  String _paymentStatus = 'pending';

  // Split payment state
  final _cashCtrl = TextEditingController(text: '0');
  final _onlineCtrl = TextEditingController(text: '0');
  final _creditCtrl = TextEditingController(text: '0');
  bool _useCash = false;
  bool _useOnline = false;
  bool _useCredit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().getProducts(context);
    });
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
    _creditCtrl.dispose();
    _searchDebounce?.cancel();
    _mobileDebounce?.cancel();
    super.dispose();
  }

  // Customer lookup — fires when mobile field hits exactly 10 digits
  void _onMobileChanged(String v) {
    final digits = v.trim();
    setState(() {});

    _mobileDebounce?.cancel();

    if (digits.length != 10) {
      if (_lookedUpCustomer != null) {
        setState(() => _lookedUpCustomer = null);
      }
      return;
    }

    _mobileDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _customerLookupLoading = true);
      try {
        final customer = await context
            .read<InvoiceProvider>()
            .fetchCustomerByMobile(digits);
        if (!mounted) return;
        setState(() {
          _lookedUpCustomer = customer;
          if (customer != null && _nameCtrl.text.trim().isEmpty) {
            _nameCtrl.text = customer.name;
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _lookedUpCustomer = null);
      } finally {
        if (mounted) setState(() => _customerLookupLoading = false);
      }
    });
  }

  // Calculations
  double get _subTotal => _cart.values.fold(0, (s, c) => s + c.lineTotal);

  double get _discountAmount {
    final val = double.tryParse(_discValCtrl.text) ?? 0;
    if (_discountType == 'percent') return (_subTotal * val / 100);
    if (_discountType == 'flat') return val.clamp(0, _subTotal);
    return 0;
  }

  double get _total => _subTotal - _discountAmount;

  double get _cashAmount => double.tryParse(_cashCtrl.text) ?? 0;

  double get _onlineAmount => double.tryParse(_onlineCtrl.text) ?? 0;

  double get _creditAmount => double.tryParse(_creditCtrl.text) ?? 0;

  double get _totalPaid =>
      (_useCash ? _cashAmount : 0) +
      (_useOnline ? _onlineAmount : 0) +
      (_useCredit ? _creditAmount : 0);

  double get _amountDue => _total - _totalPaid;

  bool get _hasCreditAvailable =>
      _lookedUpCustomer != null && _lookedUpCustomer!.creditBalance > 0;

  double get _maxCreditApplicable {
    if (!_hasCreditAvailable) return 0;
    final balance = _lookedUpCustomer!.creditBalance;
    return balance < _total ? balance : _total;
  }

  List<Map<String, dynamic>> get _paymentsPayload {
    final list = <Map<String, dynamic>>[];
    if (_useCash && _cashAmount > 0)
      list.add({'method': 'cash', 'amount': _cashAmount});
    if (_useOnline && _onlineAmount > 0)
      list.add({'method': 'online', 'amount': _onlineAmount});
    return list;
  }

  double get _creditToApplyPayload =>
      (_useCredit && _creditAmount > 0) ? _creditAmount : 0;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)\b)'), (m) => '${m[1]},')}';

  String _cartKey(int prodId, String size, int counter) =>
      '${prodId}_${size}_$counter';

  void _addToCart(ProductModel product) {
    final prodId = product.prodId!;
    final size = _pendingSize[prodId];
    if (size == null) return;
    setState(() {
      _cartCounter++;
      final key = _cartKey(prodId, size, _cartCounter);
      _cart[key] = _CartItem(
        product: product,
        qty: 1,
        unitPrice: product.fixPrice ?? 0,
        selectedSize: size,
      );
    });
  }

  void _goNext() {
    if (_step == 1) {
      if (_nameCtrl.text.trim().isEmpty) {
        AppConstant.warningMessage('Customer name is required', context);
        return;
      }
      if (_mobileCtrl.text.trim().length < 10) {
        AppConstant.warningMessage('Enter a valid mobile number', context);
        return;
      }
    }
    if (_step == 2 && _cart.isEmpty) {
      AppConstant.warningMessage('Add at least one product', context);
      return;
    }
    if (_step == 3) {
      _submit();
      return;
    }
    setState(() => _step++);
  }

  void _goBack() {
    if (_step > 1) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_useCredit) {
      if (_creditAmount <= 0) {
        AppConstant.warningMessage(
          'Credit amount must be greater than 0',
          context,
        );
        return;
      }
      if (_creditAmount > _lookedUpCustomer!.creditBalance) {
        AppConstant.warningMessage(
          'Credit (${_fmt(_creditAmount)}) exceeds available balance (${_fmt(_lookedUpCustomer!.creditBalance)})',
          context,
        );
        return;
      }
      if (_creditAmount > _total) {
        AppConstant.warningMessage(
          'Credit (${_fmt(_creditAmount)}) cannot exceed invoice total (${_fmt(_total)})',
          context,
        );
        return;
      }
    }

    if (_paymentStatus != 'pending') {
      if (!_useCash && !_useOnline && !_useCredit) {
        AppConstant.warningMessage(
          'Select at least one payment method',
          context,
        );
        return;
      }
      if (_totalPaid <= 0) {
        AppConstant.warningMessage('Enter the amount paid', context);
        return;
      }
      if (_paymentStatus == 'paid' && _totalPaid < _total) {
        AppConstant.warningMessage(
          'Total paid (${_fmt(_totalPaid)}) must equal invoice total (${_fmt(_total)}) for Paid status',
          context,
        );
        return;
      }
      if (_totalPaid > _total) {
        AppConstant.warningMessage(
          'Total paid (${_fmt(_totalPaid)}) cannot exceed invoice total (${_fmt(_total)})',
          context,
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final items = _cart.values
          .map(
            (c) => {
              'product_id': c.product.prodId,
              'quantity': c.qty,
              'size': c.selectedSize,
              'item_discount': c.itemDiscount,
              'unit_price': c.unitPrice,
            },
          )
          .toList();

      final res = await context.read<InvoiceProvider>().createInvoice(
        customerName: _nameCtrl.text.trim(),
        customerMobile: _mobileCtrl.text.trim(),
        invoiceDate: DateFormat('yyyy-MM-dd').format(_invoiceDate),
        items: items,
        notes: _notesCtrl.text.trim(),
        discountType: _discountType,
        discountValue: double.tryParse(_discValCtrl.text) ?? 0,
        creditToApply: _creditToApplyPayload,
        paymentStatus: _paymentStatus,
        payments: _paymentsPayload,
        paymentDate: DateFormat('yyyy-MM-dd').format(_invoiceDate),
      );

      if (!mounted) return;
      if (res['status'] == true) {
        AppConstant.successMessage('Invoice created successfully!', context);
        Navigator.pop(context);
      } else {
        AppConstant.errorMessage(
          res['message'] ?? 'Something went wrong',
          context,
        );
      }
    } catch (e) {
      AppConstant.errorMessage('Error: $e', context);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => _step > 1 ? _goBack() : Navigator.pop(context),
        ),
        title: Text(
          _step == 1
              ? 'New Invoice'
              : _step == 2
              ? 'Add Products'
              : 'Review & Confirm',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _step == 1
                  ? _buildStep1()
                  : _step == 2
                  ? _buildStep2()
                  : _buildStep3(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _Card(
      title: 'Customer Details',
      child: Column(
        children: [
          _Field(
            label: 'Mobile Number *',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: _onMobileChanged,
                  decoration: _dec('10-digit mobile number'),
                ),
                _buildCustomerPill(),
              ],
            ),
          ),
          _Field(
            label: 'Customer Name *',
            child: TextField(
              controller: _nameCtrl,
              decoration: _dec('Enter customer name '),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          _Field(
            label: 'Invoice Date *',
            child: GestureDetector(
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
          ),
          _Field(
            label: 'Notes (optional)',
            child: TextField(
              controller: _notesCtrl,
              decoration: _dec('Any note for this invoice'),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPill() {
    if (_customerLookupLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking customer records...',
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

    if (_lookedUpCustomer == null) return const SizedBox.shrink();

    final c = _lookedUpCustomer!;
    final hasCredit = c.creditBalance > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hasCredit
              ? AppColors.green.withOpacity(0.08)
              : AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasCredit
                ? AppColors.green.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasCredit
                  ? Icons.account_balance_wallet_rounded
                  : Icons.person_outline_rounded,
              size: 14,
              color: hasCredit ? AppColors.green : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Returning customer · ${c.name}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: hasCredit ? AppColors.green : AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasCredit)
                    Text(
                      '${_fmt(c.creditBalance)} credit available',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMedium,
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

  Widget _buildStep2() {
    return Consumer<ProductProvider>(
      builder: (ctx, provider, _) {
        return Column(
          children: [
            _Card(
              title: 'Search Products',
              child: Column(
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
                      hintText: 'Search by product name...',
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
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (provider.productList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                          provider.productList.length +
                          (provider.hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == provider.productList.length) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<ProductProvider>().loadMore();
                          });
                          return const Padding(
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
                          );
                        }
                        final p = provider.productList[i];
                        return _ProductRow(
                          product: p,
                          selectedSize: _pendingSize[p.prodId],
                          cartEntries: _cart.entries
                              .where((e) => e.key.startsWith('${p.prodId}_'))
                              .map((e) => e.value)
                              .toList(),
                          onSizeSelected: (size) =>
                              setState(() => _pendingSize[p.prodId!] = size),
                          onAdd: () => _addToCart(p),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Selected Items (${_cart.length})',
              child: _cart.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No products added yet',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        ..._cart.entries.map(
                          (entry) => _CartRow(
                            item: entry.value,
                            onIncrement: () =>
                                setState(() => entry.value.qty++),
                            onDecrement: () => setState(() {
                              if (entry.value.qty > 1) entry.value.qty--;
                            }),
                            onRemove: () =>
                                setState(() => _cart.remove(entry.key)),
                            onPriceChanged: (v) => setState(
                              () => entry.value.unitPrice =
                                  double.tryParse(v) ?? entry.value.unitPrice,
                            ),
                          ),
                        ),
                        const Divider(height: 20, color: AppColors.border),
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
                              _fmt(_subTotal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 90),
          ],
        );
      },
    );
  }

  Widget _buildStep3() {
    final isPending = _paymentStatus == 'pending';

    return Column(
      children: [
        _Card(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _nameCtrl.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (_hasCreditAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fmt(_lookedUpCustomer!.creditBalance)} credit',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${_mobileCtrl.text}  ·  ${DateFormat('dd MMM yyyy').format(_invoiceDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              if (_notesCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _notesCtrl.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Items (${_cart.length})',
          child: Column(
            children: _cart.values
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.product.prodName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                [
                                  if (c.selectedSize != null)
                                    'Size: ${c.selectedSize}',
                                  '× ${c.qty}  ·  ${_fmt(c.unitPrice)} each',
                                ].join('   '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _fmt(c.lineTotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
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
                  decoration: _dec(
                    _discountType == 'flat' ? 'Amount in ₹' : 'Percent 0–100',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Payment Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      _useCredit = false;
                      _cashCtrl.text = '0';
                      _onlineCtrl.text = '0';
                      _creditCtrl.text = '0';
                    }),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Partial',
                    icon: Icons.pie_chart_outline_rounded,
                    color: AppColors.primary,
                    selected: _paymentStatus == 'partial',
                    onTap: () => setState(() {
                      _paymentStatus = 'partial';
                    }),
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
                      _useCredit = false;
                      _cashCtrl.text = _total.toStringAsFixed(0);
                      _onlineCtrl.text = '0';
                      _creditCtrl.text = '0';
                    }),
                  ),
                ],
              ),
              if (_paymentStatus != 'pending') ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Enable one or more — combine credit, cash, and online',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                if (_hasCreditAvailable) ...[
                  _SplitPaymentRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Credit',
                    color: AppColors.green,
                    isEnabled: _useCredit,
                    controller: _creditCtrl,
                    helperText:
                        'Available: ${_fmt(_lookedUpCustomer!.creditBalance)}',
                    onToggle: (val) => setState(() {
                      _useCredit = val;
                      if (!val) {
                        _creditCtrl.text = '0';
                      } else {
                        _creditCtrl.text = _maxCreditApplicable.toStringAsFixed(
                          0,
                        );
                      }
                    }),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                ],
                _SplitPaymentRow(
                  icon: Icons.money_rounded,
                  label: 'Cash',
                  color: AppColors.primary,
                  isEnabled: _useCash,
                  controller: _cashCtrl,
                  onToggle: (val) => setState(() {
                    _useCash = val;
                    if (!val) _cashCtrl.text = '0';
                  }),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _SplitPaymentRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Online',
                  color: AppColors.orange,
                  isEnabled: _useOnline,
                  controller: _onlineCtrl,
                  onToggle: (val) => setState(() {
                    _useOnline = val;
                    if (!val) _onlineCtrl.text = '0';
                  }),
                  onChanged: (_) => setState(() {}),
                ),
                if (_useCash || _useOnline || _useCredit) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pageBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        if (_useCredit)
                          _PaySummaryRow(
                            label: 'Credit',
                            value: '₹${_creditAmount.toStringAsFixed(0)}',
                            color: AppColors.green,
                          ),
                        if (_useCash)
                          _PaySummaryRow(
                            label: 'Cash',
                            value: '₹${_cashAmount.toStringAsFixed(0)}',
                            color: AppColors.primary,
                          ),
                        if (_useOnline)
                          _PaySummaryRow(
                            label: 'Online',
                            value: '₹${_onlineAmount.toStringAsFixed(0)}',
                            color: AppColors.orange,
                          ),
                        const Divider(height: 12, color: AppColors.border),
                        _PaySummaryRow(
                          label: 'Total Paid',
                          value: '₹${_totalPaid.toStringAsFixed(0)}',
                          color: AppColors.textDark,
                          bold: true,
                        ),
                        _PaySummaryRow(
                          label: 'Amount Due',
                          value: _amountDue > 0
                              ? '₹${_amountDue.toStringAsFixed(0)}'
                              : 'Fully Paid',
                          color: _amountDue > 0
                              ? AppColors.orange
                              : AppColors.green,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_useCash && !_useOnline && !_useCredit) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pageBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Enable at least one payment method above',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              if (isPending && _hasCreditAvailable) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                _SplitPaymentRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Apply Credit',
                  color: AppColors.green,
                  isEnabled: _useCredit,
                  controller: _creditCtrl,
                  helperText:
                      'Available: ${_fmt(_lookedUpCustomer!.creditBalance)}',
                  onToggle: (val) => setState(() {
                    _useCredit = val;
                    if (!val) {
                      _creditCtrl.text = '0';
                    } else {
                      _creditCtrl.text = _maxCreditApplicable.toStringAsFixed(
                        0,
                      );
                      // If credit fully covers total, auto-flip to 'partial'
                      // (status stays partial since cash/online is 0 — backend handles)
                      _paymentStatus = 'partial';
                    }
                  }),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Summary',
          child: Column(
            children: [
              _SummaryRow(label: 'Subtotal', value: _fmt(_subTotal)),
              if (_discountType != null)
                _SummaryRow(
                  label: 'Discount',
                  value: '− ${_fmt(_discountAmount)}',
                  isRed: true,
                ),
              const Divider(height: 16, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _fmt(_total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (_useCredit) ...[
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Credit applied',
                  value: '− ${_fmt(_creditAmount)}',
                  isRed: true,
                ),
              ],
              if (!isPending) ...[
                const SizedBox(height: 8),
                _SummaryRow(label: 'Total Paid', value: _fmt(_totalPaid)),
                _SummaryRow(
                  label: 'Remaining due',
                  value: _amountDue > 0 ? _fmt(_amountDue) : _fmt(0),
                  isRed: _amountDue > 0,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _step == 3
                          ? 'Create Invoice'
                          : _step == 2
                          ? 'Review'
                          : 'Continue',
                      style: const TextStyle(
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

class _CartItem {
  final ProductModel product;
  int qty;
  double unitPrice;
  String? selectedSize;
  double itemDiscount;

  _CartItem({
    required this.product,
    this.qty = 1,
    required this.unitPrice,
    this.selectedSize,
    this.itemDiscount = 0,
  });

  double get lineTotal => (unitPrice * qty) - itemDiscount;
}

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _StepDot(n: 1, current: step, label: 'Customer'),
          _StepLine(done: step > 1),
          _StepDot(n: 2, current: step, label: 'Products'),
          _StepLine(done: step > 2),
          _StepDot(n: 3, current: step, label: 'Review'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n, current;
  final String label;

  const _StepDot({required this.n, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final done = n < current;
    final active = n == current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.green.withOpacity(0.15)
                : active
                ? AppColors.primary
                : Colors.transparent,
            border: Border.all(
              color: done
                  ? AppColors.green
                  : active
                  ? AppColors.primary
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check, size: 14, color: AppColors.green)
                : Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textLight,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;

  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 18),
      color: done ? AppColors.green : AppColors.border,
    ),
  );
}

class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final List<_CartItem> cartEntries;
  final ValueChanged<String?> onSizeSelected;
  final VoidCallback onAdd;

  const _ProductRow({
    required this.product,
    required this.selectedSize,
    required this.cartEntries,
    required this.onSizeSelected,
    required this.onAdd,
  });

  List<String> get _sizeOptions {
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
    final sizesInCart = cartEntries
        .map((e) => e.selectedSize)
        .whereType<String>()
        .toSet();
    final sizes = _sizeOptions;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cartEntries.isNotEmpty ? AppColors.green : AppColors.border,
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
              if (cartEntries.isNotEmpty)
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
                    '${cartEntries.length} added',
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedSize != null
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedSize != null
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: selectedSize != null
                        ? AppColors.primary
                        : AppColors.textLight.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    children: sizes.map((s) {
                      final isSelected = selectedSize == s;
                      final alreadyInCart = sizesInCart.contains(s);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onSizeSelected(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : alreadyInCart
                                  ? AppColors.green.withOpacity(0.1)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : alreadyInCart
                                    ? AppColors.green
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : alreadyInCart
                                        ? AppColors.green
                                        : AppColors.textMedium,
                                  ),
                                ),
                                if (alreadyInCart && !isSelected) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
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
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '↑ Select a size to add this product',
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

class _CartRow extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onIncrement, onDecrement, onRemove;
  final ValueChanged<String> onPriceChanged;

  const _CartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
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
                        item.product.prodName,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 10),
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
                      height: 36,
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
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: AppColors.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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

// Now supports optional helperText shown under the label
class _SplitPaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final String? helperText;

  const _SplitPaymentRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: isEnabled ? color : AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? color : AppColors.textMedium,
                  ),
                ),
                if (helperText != null)
                  Text(
                    helperText!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isEnabled
                          ? color.withOpacity(0.8)
                          : AppColors.textLight,
                    ),
                  ),
              ],
            ),
          ),
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
}

class _PaySummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;

  const _PaySummaryRow({
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

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
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

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
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

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isRed;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isRed ? AppColors.red : AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
