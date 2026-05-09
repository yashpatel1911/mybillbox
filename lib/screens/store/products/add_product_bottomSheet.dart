// ── Add Product Bottom Sheet ─────────────────────────────────
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/parse_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../model/category_model.dart';
import '../../../provider/category_provider.dart';
import '../../../provider/product_provider.dart';

class AddProductSheet extends StatefulWidget {
  final int catId;
  final VoidCallback onSuccess;

  const AddProductSheet({required this.catId, required this.onSuccess});

  @override
  State<AddProductSheet> createState() => AddProductSheetState();
}

class AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizesController = TextEditingController();
  final _priceController = TextEditingController();
  File? _image;
  bool _isFreeSize = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // ✅ Set once here, never inside build/dropdown method
    selectedCategoryId = widget.catId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a category',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (!_isFreeSize && _sizesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter sizes or enable Free Size',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);

    final success = await provider.createProduct(
      context,
      catId: selectedCategoryId!,
      prodName: _nameController.text.trim(),
      sizes: _isFreeSize ? null : _sizesController.text.trim(),
      isFreeSize: _isFreeSize,
      fixPrice: _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim()),
      prodImage: _image,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to add product.',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.navActiveBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Product',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Add a new product to this category',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Dropdown
                    _buildLabel('Category', isRequired: true),
                    const SizedBox(height: 8),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),

                    // Image
                    _buildLabel('Product Image', isRequired: false),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                    const SizedBox(height: 16),

                    // Product name
                    _buildLabel('Product Name', isRequired: true),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _nameController,
                      hint: 'Enter product name',
                      icon: Icons.inventory_2_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter product name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    _buildLabel('Fix Price', isRequired: false),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _priceController,
                      hint: 'Enter price in ₹ (optional)',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Free size toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free Size',
                                  style: GoogleFonts.lato(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'No size selection needed',
                                  style: GoogleFonts.lato(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFreeSize,
                            onChanged: (val) =>
                                setState(() => _isFreeSize = val),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    // Sizes (hidden when free size)
                    if (!_isFreeSize) ...[
                      const SizedBox(height: 16),
                      _buildLabel('Sizes', isRequired: true),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _sizesController,
                        hint: 'e.g. S,M,L or 28,30,32',
                        icon: Icons.format_size_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter sizes';
                          }
                          final regex = RegExp(r'^[^,\s]+(,[^,\s]+)*$');
                          if (!regex.hasMatch(v.trim())) {
                            return 'Enter valid comma-separated values';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Product',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
  }

  // ── Helper Widgets ───────────────────────────────────────

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categoryListData = Provider.of<CategoryProvider>(context);

    final seen = <int>{};
    final uniqueCategories = categoryListData.categoryList.where((cat) {
      final id = int.tryParse(cat.catId.toString());
      if (id == null || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();

    final selectedCategory = uniqueCategories.firstWhereOrNull(
          (cat) => int.parse(cat.catId.toString()) == selectedCategoryId,
    );

    return GestureDetector(
      onTap: () => _showCategoryPickerSheet(context, uniqueCategories),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedCategory != null
                ? AppColors.primary
                : AppColors.border,
            width: selectedCategory != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selectedCategory != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: selectedCategory.catImage.toString(),
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 36,
                    width: 36,
                    color: AppColors.primaryLight,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 36,
                    width: 36,
                    color: AppColors.primaryLight,
                    child: Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCategory?.catName ?? 'Select category',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: selectedCategory != null
                      ? AppColors.textDark
                      : AppColors.textLight,
                  fontWeight: selectedCategory != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPickerSheet(
      BuildContext context,
      List<CategoryModel> categories,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navActiveBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Category',
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Category list
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final catId = int.parse(cat.catId.toString());
                  final isSelected = catId == selectedCategoryId;

                  return InkWell(
                    onTap: () {
                      setState(() => selectedCategoryId = catId);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.06)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: cat.catImage.toString(),
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 48,
                                width: 48,
                                color: AppColors.primaryLight,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 48,
                                width: 48,
                                color: AppColors.primaryLight,
                                child: Icon(
                                  Icons.category_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              cat.catName,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _image == null ? AppColors.border : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: _image == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to select image',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Optional · JPG, PNG up to 5MB',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        )
            : Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                _image!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.lato(color: AppColors.textDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(color: AppColors.textLight, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}