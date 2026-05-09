import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mybillbox/screens/store/products/product_page.dart';
import 'package:provider/provider.dart';
import '../../../DBHelper/app_colors.dart';
import '../../../model/category_model.dart';
import '../../../provider/category_provider.dart';
import 'add_category_bottomSheet.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).getCategory(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final success = await provider.deleteCategory(context, category.catId);
    if (!mounted) return;
    _showSnackBar(
      success
          ? '"${category.catName}" deleted successfully!'
          : provider.errorMessage ?? 'Failed to delete category.',
      success,
    );
  }

  Future<void> _updateCategoryApi(
    File? image,
    String catName,
    int catId,
  ) async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final success = await provider.updateCategory(
      context,
      catId: catId,
      catName: catName,
      catImage: image,
    );
    if (!mounted) return;
    Navigator.pop(context);
    _showSnackBar(
      success
          ? 'Category updated successfully!'
          : provider.errorMessage ?? 'Failed to update category.',
      success,
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryListData = Provider.of<CategoryProvider>(context);

    final filteredList = categoryListData.categoryList.where((category) {
      return category.catName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
              size: 16,
            ),
          ),
        ),
        title: Text(
          'Categories',
          style: GoogleFonts.lato(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Toggle view
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
          // Search Bar
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
                decoration: InputDecoration(
                  hintText: 'Search categories...',
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
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),

          Expanded(
            child: categoryListData.loadCategory
                ? _buildLoadingState()
                : filteredList.isEmpty
                ? _buildEmptyState()
                : isGridView
                ? _buildGridView(filteredList)
                : _buildListView(filteredList),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddCategoryBottomSheet(),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Category',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildGridView(List<CategoryModel> filteredList) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) => _buildGridCard(filteredList[index]),
    );
  }

  Widget _buildListView(List<CategoryModel> filteredList) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: filteredList.length,
      itemBuilder: (context, index) => _buildListCard(filteredList[index]),
    );
  }

  Widget _buildGridCard(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Get.to(
          ProductPage(catId: category.catId, categoryName: category.catName),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.cardBg,
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: _buildCategoryImage(
                      category.catImage,
                      double.infinity,
                      double.infinity,
                    ),
                  ),
                  // Top action buttons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          bgColor: AppColors.primary.withOpacity(0.15),
                          onTap: () => _updateCategoryDialog(
                            context,
                            category.catId,
                            category.catName,
                            category.catImage,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: AppColors.red,
                          bgColor: AppColors.red.withOpacity(0.15),
                          onTap: () =>
                              _confirmCategoryDelete(context, category),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Name + status
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    category.catName,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: category.isActive
                          ? AppColors.green.withOpacity(0.12)
                          : AppColors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: category.isActive
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
      ),
    );
  }

  Widget _buildListCard(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Get.to(
          ProductPage(catId: category.catId, categoryName: category.catName),
        );
      },
      child: Container(
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
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCategoryImage(category.catImage, 64, 64),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.catName,
                      style: GoogleFonts.lato(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: category.isActive
                            ? AppColors.green.withOpacity(0.12)
                            : AppColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: category.isActive
                              ? AppColors.green
                              : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    bgColor: AppColors.navActiveBg,
                    onTap: () => _updateCategoryDialog(
                      context,
                      category.catId,
                      category.catName,
                      category.catImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    color: AppColors.red,
                    bgColor: AppColors.red.withOpacity(0.1),
                    onTap: () => _confirmCategoryDelete(context, category),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: Icon(
          Icons.category_rounded,
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
            'Loading categories...',
            style: GoogleFonts.lato(color: AppColors.textMedium, fontSize: 15),
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
              Icons.category_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            searchQuery.isEmpty ? 'No categories yet' : 'No results found',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap + Add Category to get started'
                : 'Try a different search term',
            style: GoogleFonts.lato(fontSize: 14, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmCategoryDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Delete Category',
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
            style: GoogleFonts.lato(fontSize: 14, color: AppColors.textMedium),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: '"${category.catName}"',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
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
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
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

  void _updateCategoryDialog(
    BuildContext context,
    int categoryId,
    String categoryName,
    String? catImage,
  ) {
    final TextEditingController categoryController = TextEditingController(
      text: categoryName,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    File? uploadimage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          Future<void> openImagePicker() async {
            final XFile? picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (picked != null)
              dialogSetState(() => uploadimage = File(picked.path));
          }

          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Update Category',
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
                    const SizedBox(height: 4),
                    Text(
                      'Category Image',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: openImagePicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: uploadimage != null
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: uploadimage != null
                              ? Stack(
                                  children: [
                                    Image.file(
                                      uploadimage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : (catImage != null && catImage.isNotEmpty)
                              ? Stack(
                                  children: [
                                    Image.network(
                                      catImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder(),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _imagePlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category Name *',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: categoryController,
                      style: GoogleFonts.lato(
                        color: AppColors.textDark,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter category name',
                        hintStyle: GoogleFonts.lato(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.red),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter category name'
                          : null,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
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
              Consumer<CategoryProvider>(
                builder: (context, provider, _) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: provider.isSubmitting
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            _updateCategoryApi(
                              uploadimage,
                              categoryController.text.trim(),
                              categoryId,
                            );
                          }
                        },
                  child: provider.isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Update',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 36,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select image',
            style: GoogleFonts.lato(
              color: AppColors.textMedium,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
