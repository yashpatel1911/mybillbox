import 'dart:io';
import 'package:flutter/material.dart';
import '../api_service/api_service.dart';
import '../model/category_model.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categoryList = [];
  bool _loadCategory = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final ServiceDB _apiServices = ServiceDB();

  List<CategoryModel> get categoryList => _categoryList;
  bool get loadCategory => _loadCategory;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Fetch all categories
  Future<void> getCategory(BuildContext context) async {
    _loadCategory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categoryList = await _apiServices.fetchCategory();
    } catch (e) {
      _categoryList = [];
      _errorMessage = e.toString();
    }

    _loadCategory = false;
    notifyListeners();
  }

  // Create
  Future<bool> createCategory(
      BuildContext context, {
        required String catName,
        File? catImage,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.createCategory(
        catName: catName,
        catImage: catImage,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        _categoryList.insert(0, CategoryModel.fromJson(response['data']));
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

  // Update
  Future<bool> updateCategory(
      BuildContext context, {
        required int catId,
        String? catName,
        bool? isActive,
        File? catImage,
        bool removeImage = false,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.updateCategory(
        catId: catId,
        catName: catName,
        isActive: isActive,
        catImage: catImage,
        removeImage: removeImage,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        final updated = CategoryModel.fromJson(response['data']);
        final index = _categoryList.indexWhere((c) => c.catId == catId);
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

  // Delete
  Future<bool> deleteCategory(BuildContext context, int catId) async {
    _errorMessage = null;

    try {
      final response = await _apiServices.deleteCategory(catId);

      if (response['status'] == true) {
        _categoryList.removeWhere((c) => c.catId == catId);
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