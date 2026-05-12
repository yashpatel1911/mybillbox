import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../DBHelper/app_colors.dart';
import '../DBHelper/app_constant.dart';
import '../DBHelper/session_manager.dart';
import '../api_service/api_service.dart';
import '../model/shop_category_model.dart';
import 'main_screen.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen>
    with SingleTickerProviderStateMixin {
  final _service = ServiceDB();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  File? _pickedLogo;
  List<ShopCategoryModel> _categories = [];
  ShopCategoryModel? _selectedCategory;

  bool _loading = false;
  bool _loadingCategories = true;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
    _fetchCategories();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  // ── Fetch shop categories via ServiceDB ──
  Future<void> _fetchCategories() async {
    try {
      final list = await _service.fetchShopCategories();
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
      print('fetchShopCategories error: $e');
      if (mounted) {
        AppConstant.errorMessage('Failed to load categories', context);
      }
    }
  }

  // ── Pick logo ──
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile != null) {
      setState(() => _pickedLogo = File(xfile.path));
    }
  }

  // ── Submit create-shop via ServiceDB ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      AppConstant.errorMessage('Please select a shop category', context);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await _service.createShop(
        shName: _nameCtrl.text.trim(),
        shContactNo: _contactCtrl.text.trim(),
        shAddress: _addressCtrl.text.trim(),
        shCategoryId: _selectedCategory!.catId,
        shEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        gstNo: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        shLogo: _pickedLogo,
      );

      if (res['status'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await SessionManager().setPreference('sh_id', data['sh_id'].toString());
        await SessionManager().setPreference('has_shop', '1');
        if (data['sh_logo'] != null) {
          await SessionManager().setPreference(
            'sh_logo',
            data['sh_logo'].toString(),
          );
        }

        if (mounted) {
          AppConstant.successMessage('Shop created successfully!', context);
          Get.offAll(
            () => const MainScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 600),
          );
        }
      } else {
        if (mounted) {
          AppConstant.errorMessage(
            res['message'] ?? 'Shop creation failed',
            context,
          );
        }
      }
    } catch (e) {
      print('Create shop error: $e');
      if (mounted) {
        AppConstant.errorMessage(
          'Shop creation failed. Please try again.',
          context,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(180),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.04),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(140),
                ),
                color: AppColors.green.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        const Text(
                          'Create Your Shop 🏪',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Set up your shop to start managing invoices and billing.",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMedium,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Center(child: _logoPicker()),

                        const SizedBox(height: 30),

                        _label('Shop Name *'),
                        const SizedBox(height: 8),
                        _field(
                          ctrl: _nameCtrl,
                          hint: 'e.g. Sharma General Store',
                          icon: Icons.storefront_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Shop name is required'
                              : null,
                        ),

                        const SizedBox(height: 18),

                        _label('Shop Category *'),
                        const SizedBox(height: 8),
                        _categoryDropdown(),

                        const SizedBox(height: 18),

                        _label('Contact Number *'),
                        const SizedBox(height: 8),
                        _field(
                          ctrl: _contactCtrl,
                          hint: '98XXXXXXXX',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Contact number is required';
                            }
                            if (v.trim().length < 10) {
                              return 'Enter valid contact number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _label('Email (optional)'),
                        const SizedBox(height: 8),
                        _field(
                          ctrl: _emailCtrl,
                          hint: 'shop@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 18),

                        _label('Address *'),
                        const SizedBox(height: 8),
                        _field(
                          ctrl: _addressCtrl,
                          hint: 'Shop address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Address is required'
                              : null,
                        ),

                        const SizedBox(height: 18),

                        _label('GST Number (optional)'),
                        const SizedBox(height: 8),
                        _field(
                          ctrl: _gstCtrl,
                          hint: 'GSTIN',
                          icon: Icons.badge_outlined,
                          validator: (v) {
                            if (v != null &&
                                v.trim().isNotEmpty &&
                                v.trim().length > 11) {
                              return 'GST must not exceed 11 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Shop',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPicker() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pickedLogo != null ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            if (_pickedLogo != null)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 12,
              ),
          ],
        ),
        child: _pickedLogo != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.file(_pickedLogo!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add Logo',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                  Text(
                    '(optional)',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _categoryDropdown() {
    if (_loadingCategories) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Center(
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

    return DropdownButtonFormField<ShopCategoryModel>(
      value: _selectedCategory,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textLight,
      ),
      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Select category',
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: AppColors.textLight,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      items: _categories
          .map(
            (c) => DropdownMenuItem<ShopCategoryModel>(
              value: c,
              child: Text(c.catName),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      color: AppColors.textDark,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.8),
        ),
        errorStyle: const TextStyle(color: AppColors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}
