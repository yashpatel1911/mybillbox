import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../model/product_model.dart';
import '../../../provider/product_provider.dart';
import 'add_product_bottomSheet.dart';

class ProductPage extends StatefulWidget {
  final int catId;
  final String categoryName;

  const ProductPage({
    super.key,
    required this.catId,
    required this.categoryName,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isGridView = true;

  // ── Scroll controller for load more ───────────
  final ScrollController _scrollCtrl = ScrollController();

  // ── Debounce for search ───────────────────────
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().getProducts(
        context,
        catId: widget.catId,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Trigger loadMore near bottom ──────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 250) {
      context.read<ProductProvider>().loadMore();
    }
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.lato(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.green : AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final provider = context.read<ProductProvider>();
    final success  = await provider.deleteProduct(context, product.prodId);
    if (!mounted) return;
    _showSnackBar(
      success
          ? '"${product.prodName}" deleted successfully!'
          : provider.errorMessage ?? 'Failed to delete product.',
      success,
    );
  }

  Future<void> _submitUpdateProduct({
    required int prodId,
    required String prodName,
    required int catId,
    String? sizes,
    bool isFreeSize  = false,
    double? fixPrice,
    File? prodImage,
  }) async {
    final provider = context.read<ProductProvider>();
    final success  = await provider.updateProduct(
      context,
      prodId:     prodId,
      catId:      catId,
      prodName:   prodName,
      sizes:      sizes,
      isFreeSize: isFreeSize,
      fixPrice:   fixPrice,
      prodImage:  prodImage,
    );
    if (!mounted) return;
    Navigator.pop(context);
    _showSnackBar(
      success
          ? 'Product updated successfully!'
          : provider.errorMessage ?? 'Failed to update product.',
      success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final list = provider.productList;

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.pageBg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                  size: 16,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: GoogleFonts.lato(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${list.length} Products',
                  style: GoogleFonts.lato(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => setState(() => isGridView = !isGridView),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Search ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.lato(color: AppColors.textDark),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      // Debounce: fire API 400ms after user stops typing
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 400),
                            () => context.read<ProductProvider>().getProducts(
                          context,
                          catId:  widget.catId,
                          search: value.trim().isEmpty
                              ? null
                              : value.trim(),
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.lato(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.textLight,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                          _searchDebounce?.cancel();
                          // Reset to full list
                          context.read<ProductProvider>().getProducts(
                            context,
                            catId: widget.catId,
                          );
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────
              Expanded(
                child: provider.loadProduct
                    ? _buildLoadingState()
                    : list.isEmpty
                    ? _buildEmptyState()
                    : isGridView
                    ? _buildGridView(list, provider)
                    : _buildListView(list, provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddProductSheet(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Add Product',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  // ── Grid ──────────────────────────────────────
  Widget _buildGridView(List<ProductModel> list, ProductProvider provider) {
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      // +1 for the load-more row when hasMore
      itemCount: list.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // ── Load more spinner ──
        if (index == list.length) {
          return _buildLoadMoreSpinner();
        }
        return _buildGridCard(list[index]);
      },
    );
  }

  // ── List ──────────────────────────────────────
  Widget _buildListView(List<ProductModel> list, ProductProvider provider) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      // +1 for load-more row when hasMore
      itemCount: list.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // ── Load more spinner ──
        if (index == list.length) {
          return _buildLoadMoreSpinner();
        }
        return _buildListCard(list[index]);
      },
    );
  }

  // ── Load more spinner row ─────────────────────
  Widget _buildLoadMoreSpinner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more...',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: _buildProductImage(
                    product.prodImage,
                    double.infinity,
                    double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withOpacity(0.15),
                        onTap: () =>
                            _showUpdateProductDialog(context, product),
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        color: AppColors.red,
                        bgColor: AppColors.red.withOpacity(0.15),
                        onTap: () => _confirmDelete(context, product),
                      ),
                    ],
                  ),
                ),
                if (product.isFreeSize)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Free Size',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.prodName,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (product.fixPrice != null)
                  Text(
                    '₹${product.fixPrice!.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                if (product.sizes != null && !product.isFreeSize)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.sizes!,
                      style: GoogleFonts.lato(
                        color: AppColors.textMedium,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? AppColors.green.withOpacity(0.12)
                        : AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: product.isActive
                          ? AppColors.green
                          : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildProductImage(product.prodImage, 70, 70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.prodName,
                    style: GoogleFonts.lato(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (product.fixPrice != null)
                    Text(
                      '₹${product.fixPrice!.toStringAsFixed(0)}',
                      style: GoogleFonts.lato(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.isFreeSize)
                        _buildChip('Free Size', AppColors.cyan),
                      if (!product.isFreeSize && product.sizes != null)
                        _buildChip(product.sizes!, AppColors.purple),
                      const SizedBox(width: 6),
                      _buildChip(
                        product.isActive ? 'Active' : 'Inactive',
                        product.isActive ? AppColors.green : AppColors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.navActiveBg,
                  onTap: () => _showUpdateProductDialog(context, product),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.red,
                  bgColor: AppColors.red.withOpacity(0.1),
                  onTap: () => _confirmDelete(context, product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: Icon(
          Icons.inventory_2_rounded,
          color: AppColors.primary.withOpacity(0.4),
          size: 32,
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.primary.withOpacity(0.4),
          size: 28,
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.primaryLight,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style:
            GoogleFonts.lato(color: AppColors.textMedium, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            searchQuery.isEmpty ? 'No products yet' : 'No results found',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap + Add Product to get started'
                : 'Try a different search term',
            style:
            GoogleFonts.lato(fontSize: 14, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  // ── Delete Confirm ────────────────────────────
  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Product',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style:
            GoogleFonts.lato(fontSize: 14, color: AppColors.textMedium),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: '"${product.prodName}"',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Product Bottom Sheet ──────────────────
  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddProductSheet(
          catId: widget.catId,
          onSuccess: () => _showSnackBar('Product added successfully!', true),
        ),
      ),
    );
  }

  // ── Update Product Dialog ─────────────────────
  void _showUpdateProductDialog(BuildContext context, ProductModel product) {
    final nameController  = TextEditingController(text: product.prodName);
    final sizesController = TextEditingController(text: product.sizes ?? '');
    final priceController = TextEditingController(
        text: product.fixPrice?.toStringAsFixed(0) ?? '');
    final formKey = GlobalKey<FormState>();
    File? newImage;
    bool isFreeSize = product.isFreeSize;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navActiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Product',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Image picker
                  InkWell(
                    onTap: () async {
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null)
                        dialogSetState(
                                () => newImage = File(picked.path));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: newImage != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: newImage != null
                            ? Image.file(newImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity)
                            : (product.prodImage != null)
                            ? Image.network(product.prodImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity)
                            : Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 32,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to add image',
                                style: GoogleFonts.lato(
                                  color: AppColors.textMedium,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDialogField(
                    controller: nameController,
                    label: 'Product Name *',
                    hint: 'Enter product name',
                    icon: Icons.inventory_2_outlined,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter product name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogField(
                    controller: priceController,
                    label: 'Fix Price (Optional)',
                    hint: 'Enter price',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  // Free size toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.pageBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.straighten_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Free Size',
                              style: GoogleFonts.lato(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Switch(
                          value: isFreeSize,
                          onChanged: (val) =>
                              dialogSetState(() => isFreeSize = val),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  if (!isFreeSize) ...[
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: sizesController,
                      label: 'Sizes',
                      hint: 'e.g. S,M,L or 28,30,32',
                      icon: Icons.format_size_rounded,
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.lato(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600)),
            ),
            Consumer<ProductProvider>(
              builder: (context, provider, _) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: provider.isSubmitting
                    ? null
                    : () {
                  if (formKey.currentState!.validate()) {
                    _submitUpdateProduct(
                      prodId:     product.prodId,
                      prodName:   nameController.text.trim(),
                      catId:      product.catId,
                      sizes:      isFreeSize
                          ? null
                          : sizesController.text.trim().isEmpty
                          ? null
                          : sizesController.text.trim(),
                      isFreeSize: isFreeSize,
                      fixPrice:   priceController.text.trim().isEmpty
                          ? null
                          : double.tryParse(
                          priceController.text.trim()),
                      prodImage: newImage,
                    );
                  }
                },
                child: provider.isSubmitting
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text('Update',
                    style:
                    GoogleFonts.lato(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.lato(color: AppColors.textDark, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            GoogleFonts.lato(color: AppColors.textLight, fontSize: 14),
            prefixIcon:
            Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.pageBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.red)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}