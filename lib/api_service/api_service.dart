import 'dart:io';
import '../DBHelper/environment.dart';
import '../DBHelper/session_manager.dart';
import '../DBHelper/wp-api.dart';
import '../model/category_model.dart';
import '../model/employee_model.dart';
import '../model/product_model.dart';
import '../model/profile_model.dart';

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

    return await Api.post(
      Environment().changePassword,
      body,
      token: _token,
    ) as Map<String, dynamic>;
  }
}
