import 'package:flutter/material.dart';
import '../../api_service/api_service.dart';
import '../../model/expense/expense_category_model.dart';

class ExpenseCategoryProvider with ChangeNotifier {
  List<ExpenseCategoryModel> _categoryList = [];
  bool _loadCategory = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final ServiceDB _apiServices = ServiceDB();

  List<ExpenseCategoryModel> get categoryList => _categoryList;

  bool get loadCategory => _loadCategory;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  // ── Fetch all expense categories ──
  Future<void> getExpenseCategory(
    BuildContext context, {
    String? search,
  }) async {
    _loadCategory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categoryList = await _apiServices.fetchExpenseCategory(search: search);
    } catch (e) {
      _categoryList = [];
      _errorMessage = e.toString();
    }

    _loadCategory = false;
    notifyListeners();
  }

  // ── Create ──
  Future<bool> createExpenseCategory(
    BuildContext context, {
    required String expCatName,
    String? expCatDescription,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.createExpenseCategory(
        expCatName: expCatName,
        expCatDescription: expCatDescription,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        _categoryList.insert(
          0,
          ExpenseCategoryModel.fromJson(response['data']),
        );
        notifyListeners();
        return true;
      }

      _errorMessage = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Update ──
  Future<bool> updateExpenseCategory(
    BuildContext context, {
    required int expCatId,
    String? expCatName,
    String? expCatDescription,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.updateExpenseCategory(
        expCatId: expCatId,
        expCatName: expCatName,
        expCatDescription: expCatDescription,
        isActive: isActive,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        final updated = ExpenseCategoryModel.fromJson(response['data']);
        final index = _categoryList.indexWhere((c) => c.expCatId == expCatId);
        if (index != -1) {
          _categoryList[index] = updated;
          notifyListeners();
        }
        return true;
      }

      _errorMessage = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete ──
  Future<bool> deleteExpenseCategory(BuildContext context, int expCatId) async {
    _errorMessage = null;

    try {
      final response = await _apiServices.deleteExpenseCategory(expCatId);

      if (response['status'] == true) {
        _categoryList.removeWhere((c) => c.expCatId == expCatId);
        notifyListeners();
        return true;
      }

      _errorMessage = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
