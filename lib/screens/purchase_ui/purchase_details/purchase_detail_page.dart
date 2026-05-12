import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybillbox/screens/purchase_ui/purchase_details/purchase_edit_sections.dart';
import 'package:mybillbox/screens/purchase_ui/purchase_details/purchase_view_sections.dart';
import 'package:provider/provider.dart';
import '../../../../DBHelper/app_colors.dart';
import '../../../../DBHelper/app_constant.dart';
import '../../../../model/purchase_details/purchase_model.dart';
import '../../../../provider/purchase_provider.dart';
import '../../../../provider/product_provider.dart';
import '../../../model/purchase_details/purchase_cart_item_model.dart';

class PurchaseDetailPage extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  PurchaseModel? _purchase;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;

  // ── Supplier edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _purchaseDate;

  // ── Items edit state
  final Map<String, PurchaseCartItem> _cart = {};
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

  // ────────────────────────────────────────────────────
  //  Lifecycle
  // ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _discValCtrl = TextEditingController(text: '0');
    _purchaseDate = DateTime.now();
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

  // ────────────────────────────────────────────────────
  //  Data loading
  // ────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final purchase = await context.read<PurchaseProvider>().fetchPurchaseById(
        widget.purchaseId,
      );
      if (mounted && purchase != null) {
        setState(() {
          _purchase = purchase;
          _loading = false;
          _nameCtrl.text = purchase.customerName;
          _mobileCtrl.text = purchase.customerMobile;
          _notesCtrl.text = purchase.notes;
          _purchaseDate =
              DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ────────────────────────────────────────────────────
  //  Edit mode
  // ────────────────────────────────────────────────────

  void _enterEditMode() {
    final purchase = _purchase!;
    _nameCtrl.text = purchase.customerName;
    _mobileCtrl.text = purchase.customerMobile;
    _notesCtrl.text = purchase.notes;
    _purchaseDate = DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now();

    _cart.clear();
    _cartCounter = 0;
    _pendingSize.clear();
    for (final item in purchase.items) {
      _cartCounter++;
      final key = '${item.productId}_${item.size ?? "none"}_$_cartCounter';
      _cart[key] = PurchaseCartItem(
        productId: item.productId,
        productName: item.productName,
        qty: item.quantity,
        unitPrice: item.unitPrice,
        selectedSize: item.size,
        itemDiscount: item.itemDiscount,
      );
    }

    _discountType = purchase.discountType;
    _discValCtrl.text = purchase.discountValue > 0
        ? purchase.discountValue.toStringAsFixed(0)
        : '0';
    _paymentStatus = purchase.paymentStatus;
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

  // ────────────────────────────────────────────────────
  //  Computed values
  // ────────────────────────────────────────────────────

  double get _subTotal => _cart.values.fold(0, (s, c) => s + c.lineTotal);

  double get _discountAmt {
    final val = double.tryParse(_discValCtrl.text) ?? 0;
    if (_discountType == 'percent') return _subTotal * val / 100;
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

  // ────────────────────────────────────────────────────
  //  Cart mutations
  // ────────────────────────────────────────────────────

  void _addToCartFromProduct(dynamic product) {
    final prodId = product.prodId as int;
    final size = _pendingSize[prodId];
    if (size == null) return;
    setState(() {
      _cartCounter++;
      final key = '${prodId}_${size}_$_cartCounter';
      _cart[key] = PurchaseCartItem(
        productId: prodId,
        productName: product.prodName as String,
        qty: 1,
        unitPrice: (product.fixPrice as double?) ?? 0,
        selectedSize: size,
        itemDiscount: 0,
      );
    });
  }

  void _onSizeSelected(String prodIdStr, String? size) {
    final prodId = int.tryParse(prodIdStr);
    if (prodId == null) return;
    setState(() => _pendingSize[prodId] = size);
  }

  void _onIncrement(String key) => setState(() => _cart[key]?.qty++);

  void _onDecrement(String key) => setState(() {
    if ((_cart[key]?.qty ?? 0) > 1) _cart[key]!.qty--;
  });

  void _onRemove(String key) => setState(() => _cart.remove(key));

  void _onPriceChanged(String key, String val) => setState(() {
    final item = _cart[key];
    if (item != null) {
      item.unitPrice = double.tryParse(val) ?? item.unitPrice;
    }
  });

  // ────────────────────────────────────────────────────
  //  Payment chip & split-row handlers
  // ────────────────────────────────────────────────────

  void _onStatusChanged(String status) {
    setState(() {
      _paymentStatus = status;
      if (status == 'pending') {
        _useCash = false;
        _useOnline = false;
        _cashCtrl.text = '0';
        _onlineCtrl.text = '0';
      } else if (status == 'paid') {
        _useCash = true;
        _useOnline = false;
        final remaining = (_editTotal - (_purchase?.amountPaid ?? 0)).clamp(
          0.0,
          double.infinity,
        );
        _cashCtrl.text = remaining.toStringAsFixed(0);
        _onlineCtrl.text = '0';
      }
    });
  }

  void _onCashToggle(bool val) => setState(() {
    _useCash = val;
    if (!val) {
      _cashCtrl.text = '0';
    } else if (_useOnline) {
      final due = (_editTotal - (_purchase?.amountPaid ?? 0)).clamp(
        0.0,
        double.infinity,
      );
      final rem = due - _onlineAmount;
      _onlineCtrl.text = rem > 0 ? rem.toStringAsFixed(0) : '0';
    }
  });

  void _onOnlineToggle(bool val) => setState(() {
    _useOnline = val;
    if (!val) {
      _onlineCtrl.text = '0';
    } else if (_useCash) {
      final due = (_editTotal - (_purchase?.amountPaid ?? 0)).clamp(
        0.0,
        double.infinity,
      );
      final rem = due - _cashAmount;
      _onlineCtrl.text = rem > 0 ? rem.toStringAsFixed(0) : '0';
    }
  });

  void _onCashChanged(String v) {
    if (_useOnline) {
      setState(() {
        final due = (_editTotal - (_purchase?.amountPaid ?? 0)).clamp(
          0.0,
          double.infinity,
        );
        final rem = (due - (double.tryParse(v) ?? 0)).clamp(
          0.0,
          double.infinity,
        );
        _onlineCtrl.text = rem.toStringAsFixed(0);
      });
    }
  }

  void _onOnlineChanged(String v) {
    if (_useCash) {
      setState(() {
        final due = (_editTotal - (_purchase?.amountPaid ?? 0)).clamp(
          0.0,
          double.infinity,
        );
        final rem = (due - (double.tryParse(v) ?? 0)).clamp(
          0.0,
          double.infinity,
        );
        _cashCtrl.text = rem.toStringAsFixed(0);
      });
    }
  }

  // ────────────────────────────────────────────────────
  //  Save
  // ────────────────────────────────────────────────────

  Future<void> _saveEdit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppConstant.warningMessage('Supplier name is required', context);
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
    if (_paymentStatus != 'pending' && (_useCash || _useOnline)) {
      final amountDue = (_editTotal - (_purchase!.amountPaid)).clamp(
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

      final res = await context.read<PurchaseProvider>().updatePurchase(
        purchaseId: widget.purchaseId,
        customerName: _nameCtrl.text.trim(),
        customerMobile: _mobileCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        purchaseDate: DateFormat('yyyy-MM-dd').format(_purchaseDate),
        items: items,
        discountType: _discountType,
        discountValue: double.tryParse(_discValCtrl.text) ?? 0,
        paymentStatus: _paymentStatus,
        payments: _paymentsPayload,
      );

      if (!mounted) return;
      if (res['status'] == true) {
        AppConstant.successMessage('Purchase updated!', context);
        setState(() {
          _purchase = context.read<PurchaseProvider>().selectedPurchase;
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

  // ────────────────────────────────────────────────────
  //  Helpers
  // ────────────────────────────────────────────────────

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

  // ────────────────────────────────────────────────────
  //  Build
  // ────────────────────────────────────────────────────

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
          _editMode ? 'Edit Purchase' : 'Purchase Detail',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (!_loading && _purchase != null && !_purchase!.isCancelled)
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
          : _purchase == null
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

  // ── View mode layout ─────────────────────────────────
  Widget _buildViewMode() => Column(
    children: [
      PurchaseHeaderCard(
        purchase: _purchase!,
        statusColor: _statusColor,
        statusLabel: _statusLabel,
      ),
      const SizedBox(height: 12),
      PurchaseCustomerCard(purchase: _purchase!),
      const SizedBox(height: 12),
      PurchaseItemsCard(purchase: _purchase!, fmt: _fmt),
      const SizedBox(height: 12),
      PurchaseSummaryCard(purchase: _purchase!, fmt: _fmt),
      const SizedBox(height: 12),
      if (_purchase!.paymentStatus != 'paid')
        AddPaymentCard(
          purchase: _purchase!,
          purchaseId: widget.purchaseId,
          fmt: _fmt,
          onPaymentSuccess: _load,
        ),
    ],
  );

  // ── Edit mode layout ─────────────────────────────────
  Widget _buildEditMode() => Column(
    children: [
      EditSupplierCard(
        nameCtrl: _nameCtrl,
        mobileCtrl: _mobileCtrl,
        notesCtrl: _notesCtrl,
        purchaseDate: _purchaseDate,
        onDateChanged: (d) => setState(() => _purchaseDate = d),
      ),
      const SizedBox(height: 12),
      EditProductsCard(
        cart: _cart,
        pendingSize: _pendingSize,
        searchCtrl: _searchCtrl,
        searchQuery: _searchQuery,
        subTotal: _subTotal,
        fmt: _fmt,
        onSearchClear: () {
          _searchCtrl.clear();
          setState(() => _searchQuery = '');
          _searchDebounce?.cancel();
          context.read<ProductProvider>().getProducts(context);
        },
        onSearchChanged: (v) {
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
        onAddToCart: _addToCartFromProduct,
        onSizeSelected: _onSizeSelected,
        onRemoveFromCart: _onRemove,
        onIncrement: _onIncrement,
        onDecrement: _onDecrement,
        onPriceChanged: _onPriceChanged,
      ),
      const SizedBox(height: 12),
      EditDiscountCard(
        discountType: _discountType,
        discValCtrl: _discValCtrl,
        onTypeChanged: (type) => setState(() {
          _discountType = type;
          _discValCtrl.text = '0';
        }),
      ),
      const SizedBox(height: 12),
      EditPurchasePaymentCard(
        purchase: _purchase!,
        paymentStatus: _paymentStatus,
        useCash: _useCash,
        useOnline: _useOnline,
        cashCtrl: _cashCtrl,
        onlineCtrl: _onlineCtrl,
        editTotal: _editTotal,
        fmt: _fmt,
        onStatusChanged: _onStatusChanged,
        onCashToggle: _onCashToggle,
        onOnlineToggle: _onOnlineToggle,
        onCashChanged: _onCashChanged,
        onOnlineChanged: _onOnlineChanged,
      ),
      const SizedBox(height: 12),
      EditSummaryCard(
        subTotal: _subTotal,
        discountAmt: _discountAmt,
        editTotal: _editTotal,
        totalPaid: _totalPaid,
        showPayment: _useCash || _useOnline,
        discountType: _discountType,
        fmt: _fmt,
      ),
      const SizedBox(height: 20),
    ],
  );

  // ── Error state ───────────────────────────────────────
  Widget _errorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        const Text(
          'Purchase not found',
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
