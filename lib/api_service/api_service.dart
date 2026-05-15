import 'dart:io';
import '../DBHelper/environment.dart';
import '../DBHelper/session_manager.dart';
import '../DBHelper/wp-api.dart';
import '../model/category_model.dart';
import '../model/employee_model.dart';
import '../model/expense/expense_category_model.dart';
import '../model/product_model.dart';
import '../model/profile_model.dart';
import '../model/report_summary_model.dart';
import '../model/shop_category_model.dart';

class ServiceDB {
  final SessionManager setting = SessionManager();

  String get _token => setting.token;

  // ──────────────────────────────────────────────────
  // CATEGORIES
  // ──────────────────────────────────────────────────

  Future<List<CategoryModel>> fetchCategory() async {
    final response =
        await Api.get(Environment().fetchCategory, token: _token)
            as Map<String, dynamic>;

    if (response['status'] == true) {
      return (response['data'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createCategory({
    required String catName,
    File? catImage,
  }) async {
    return await Api.uploadFiles(
          Environment().createCategory,
          fields: {'cat_name': catName},
          files: catImage != null ? {'cat_image': catImage.path} : {},
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCategory({
    required int catId,
    String? catName,
    bool? isActive,
    File? catImage,
    bool removeImage = false,
  }) async {
    final fields = <String, String>{};
    if (catName != null) fields['cat_name'] = catName;
    if (isActive != null) fields['is_active'] = isActive.toString();
    if (removeImage) fields['remove_image'] = 'true';

    return await Api.uploadFiles(
          '${Environment().updateCategory}$catId/',
          method: 'PATCH',
          fields: fields,
          files: catImage != null ? {'cat_image': catImage.path} : {},
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteCategory(int catId) async {
    return await Api.delete(
          '${Environment().deleteCategory}$catId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // PRODUCTS
  // ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProducts({
    int? catId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'page_size': '$pageSize'};
    if (catId != null && catId > 0) params['cat_id'] = '$catId';
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response =
        await Api.get(Environment().fetchProducts, query: params, token: _token)
            as Map<String, dynamic>;

    if (response['status'] == true) {
      return {
        'products': (response['data'] as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        'has_next': response['has_next'] as bool? ?? false,
        'total_count': response['total_count'] as int? ?? 0,
        'total_pages': response['total_pages'] as int? ?? 1,
        'page': response['page'] as int? ?? page,
      };
    }

    return {
      'products': <ProductModel>[],
      'has_next': false,
      'total_count': 0,
      'total_pages': 1,
      'page': page,
    };
  }

  Future<Map<String, dynamic>> createProduct({
    required int catId,
    required String prodName,
    String? sizes,
    bool isFreeSize = false,
    double? fixPrice,
    File? prodImage,
  }) async {
    final fields = <String, String>{
      'cat_id': catId.toString(),
      'prod_name': prodName,
      'is_free_size': isFreeSize.toString(),
    };
    if (sizes != null) fields['sizes'] = sizes;
    if (fixPrice != null) fields['fix_price'] = fixPrice.toString();

    return await Api.uploadFiles(
          Environment().createProduct,
          fields: fields,
          files: prodImage != null ? {'prod_image': prodImage.path} : {},
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct({
    required int prodId,
    int? catId,
    String? prodName,
    String? sizes,
    bool? isFreeSize,
    double? fixPrice,
    bool? isActive,
    File? prodImage,
    bool removeImage = false,
  }) async {
    final fields = <String, String>{};
    if (catId != null) fields['cat_id'] = catId.toString();
    if (prodName != null) fields['prod_name'] = prodName;
    if (sizes != null) fields['sizes'] = sizes;
    if (isFreeSize != null) fields['is_free_size'] = isFreeSize.toString();
    if (fixPrice != null) fields['fix_price'] = fixPrice.toString();
    if (isActive != null) fields['is_active'] = isActive.toString();
    if (removeImage) fields['remove_image'] = 'true';

    return await Api.uploadFiles(
          '${Environment().updateProduct}$prodId/',
          method: 'PUT',
          fields: fields,
          files: prodImage != null ? {'prod_image': prodImage.path} : {},
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteProduct(int prodId) async {
    return await Api.delete(
          '${Environment().deleteProduct}$prodId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // EMPLOYEES
  // ──────────────────────────────────────────────────

  Future<List<EmployeeModel>> fetchEmployees() async {
    final response =
        await Api.get(Environment().fetchEmployees, token: _token)
            as Map<String, dynamic>;

    if (response['status'] == true) {
      return (response['data'] as List)
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> addEmployee({
    required String name,
    required String username,
    required String contactNo,
    String? email,
    required String password,
    required String role,
  }) async {
    return await Api.post(Environment().addEmployee, {
          'name': name,
          'username': username,
          'contact_no': contactNo,
          'email': email,
          'password': password,
          'role': role,
        }, token: _token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateEmployee({
    required int empId,
    required String name,
    required String contactNo,
    String? email,
    required String role,
    required bool isActive,
  }) async {
    return await Api.put('${Environment().updateEmployee}$empId/', {
          'name': name,
          'contact_no': contactNo,
          'email': email,
          'role': role,
          'is_active': isActive,
        }, token: _token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteEmployee(int empId) async {
    return await Api.delete(
          '${Environment().deleteEmployee}$empId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // PROFILE
  // ──────────────────────────────────────────────────
  Future<ProfileModel?> fetchMyProfile() async {
    final response =
        await Api.get(Environment().getProfile, token: _token)
            as Map<String, dynamic>;

    if (response['status'] == true) {
      return ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ──────────────────────────────────────────────────
  // 2. SERVICE — add this method to ServiceDB
  // ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> changePassword({
    String? existingPassword,
    required String newPassword,
  }) async {
    final body = <String, dynamic>{
      'new_password': newPassword,
      if (existingPassword != null) 'existing_password': existingPassword,
    };

    return await Api.post(Environment().changePassword, body, token: _token)
        as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────
  // EXPENSE CATEGORY APIs
  // ─────────────────────────────────────────

  Future<List<ExpenseCategoryModel>> fetchExpenseCategory({
    String? search,
  }) async {
    String url = Environment().fetchExpenseCategory;
    if (search != null && search.trim().isNotEmpty) {
      url += '?search=${Uri.encodeComponent(search.trim())}';
    }

    final response = await Api.get(url, token: _token) as Map<String, dynamic>;

    if (response['status'] == true) {
      return (response['data'] as List)
          .map((e) => ExpenseCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createExpenseCategory({
    required String expCatName,
    String? expCatDescription,
  }) async {
    return await Api.post(Environment().createExpenseCategory, {
          'exp_cat_name': expCatName,
          if (expCatDescription != null)
            'exp_cat_description': expCatDescription,
        }, token: _token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpenseCategory({
    required int expCatId,
    String? expCatName,
    String? expCatDescription,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (expCatName != null) body['exp_cat_name'] = expCatName;
    if (expCatDescription != null)
      body['exp_cat_description'] = expCatDescription;
    if (isActive != null) body['is_active'] = isActive.toString();

    return await Api.patch(
          '${Environment().updateExpenseCategory}$expCatId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteExpenseCategory(int expCatId) async {
    return await Api.delete(
          '${Environment().deleteExpenseCategory}$expCatId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────
  // EXPENSES APIs
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>> fetchExpenses({
    String filter = 'overall', // 'today' | 'overall'
    String? search,
    int? expCatId,
    String? paymentMethod,
  }) async {
    final params = <String, String>{'filter': filter};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (expCatId != null) params['exp_cat_id'] = expCatId.toString();
    if (paymentMethod != null) params['payment_method'] = paymentMethod;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = '${Environment().fetchExpenses}?$query';
    final response = await Api.get(url, token: _token) as Map<String, dynamic>;
    return response;
  }

  Future<Map<String, dynamic>> createExpense({
    String? partyName,
    required int expCatId,
    required double amount,
    required String paidOn, // 'YYYY-MM-DD'
    required String paymentMethod, // 'CASH' | 'ONLINE'
    String? notes,
  }) async {
    return await Api.post(Environment().createExpense, {
          if (partyName != null && partyName.isNotEmpty)
            'party_name': partyName,
          'exp_cat_id': expCatId,
          'amount': amount,
          'paid_on': paidOn,
          'payment_method': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }, token: _token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpense({
    required int expId,
    String? partyName,
    int? expCatId,
    double? amount,
    String? paidOn,
    String? paymentMethod,
    String? notes,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (partyName != null) body['party_name'] = partyName;
    if (expCatId != null) body['exp_cat_id'] = expCatId;
    if (amount != null) body['amount'] = amount;
    if (paidOn != null) body['paid_on'] = paidOn;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (notes != null) body['notes'] = notes;
    if (isActive != null) body['is_active'] = isActive.toString();

    return await Api.patch(
          '${Environment().updateExpense}$expId/',
          body,
          token: _token,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteExpense(int expId) async {
    return await Api.delete(
          '${Environment().deleteExpense}$expId/',
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────
  // SHOP CATEGORIES
  // ──────────────────────────────────────────────────

  Future<List<ShopCategoryModel>> fetchShopCategories() async {
    final response =
        await Api.get(Environment().shopCategories, token: _token)
            as Map<String, dynamic>;

    if (response['status'] == true) {
      return (response['data'] as List)
          .map((e) => ShopCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ──────────────────────────────────────────────────
  // SHOP
  // ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> createShop({
    required String shName,
    required String shContactNo,
    required String shAddress,
    required int shCategoryId,
    String? shEmail,
    String? gstNo,
    File? shLogo,
  }) async {
    final fields = <String, String>{
      'sh_name': shName,
      'sh_contact_no': shContactNo,
      'sh_address': shAddress,
      'sh_category_id': shCategoryId.toString(),
    };
    if (shEmail != null && shEmail.isNotEmpty) fields['sh_email'] = shEmail;
    if (gstNo != null && gstNo.isNotEmpty) fields['gst_no'] = gstNo;

    return await Api.uploadFiles(
          Environment().createShop,
          fields: fields,
          files: shLogo != null ? {'sh_logo': shLogo.path} : {},
          token: _token,
        )
        as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────
  // REPORTS APIs
  // ─────────────────────────────────────────

  /// Fetch reports summary for the given date range.
  /// Returns parsed ReportSummary on success, throws on failure.
  ///
  /// Backend wraps response as {status, message, data}.
  Future<ReportSummary> fetchReportsSummary({
    required String fromDate, // 'YYYY-MM-DD'
    required String toDate, // 'YYYY-MM-DD'
  }) async {
    final url = '${Environment().reportsSummary}?from=$fromDate&to=$toDate';

    final response = await Api.get(url, token: _token) as Map<String, dynamic>;

    if (response['status'] == true) {
      return ReportSummary.fromJson(response['data'] as Map<String, dynamic>);
    }

    // Surface the server message so the provider/UI can show it
    throw Exception(
      response['message']?.toString() ?? 'Failed to load summary',
    );
  }
}
