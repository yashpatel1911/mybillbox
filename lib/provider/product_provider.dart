import 'dart:io';
import 'package:flutter/material.dart';
import '../api_service/api_service.dart';
import '../model/product_model.dart';

class ProductProvider with ChangeNotifier {
  // ── Product list state ─────────────────────────
  List<ProductModel> _productList = [];
  bool _loadProduct               = false;
  bool _isSubmitting              = false;
  bool _isLoadingMore             = false;
  String? _errorMessage;

  // ── Pagination state ───────────────────────────
  int  _currentPage = 1;
  bool _hasMore     = true;

  // ── Active filter memory (used by loadMore) ────
  String? _activeSearch;
  int?    _activeCatId;

  final ServiceDB _apiServices = ServiceDB();

  // ── Getters ────────────────────────────────────
  List<ProductModel> get productList  => _productList;
  bool get loadProduct                => _loadProduct;
  bool get isSubmitting               => _isSubmitting;
  bool get isLoadingMore              => _isLoadingMore;
  bool get hasMore                    => _hasMore;
  String? get errorMessage            => _errorMessage;

  // ── Fetch page 1 — fresh load or new search ────
  Future<void> getProducts(
      BuildContext context, {
        int?    catId,
        String? search,
      }) async {
    _loadProduct  = true;
    _errorMessage = null;
    _currentPage  = 1;
    _hasMore      = true;
    _activeSearch = search;
    _activeCatId  = catId;
    notifyListeners();

    try {
      final result = await _apiServices.fetchProducts(
        catId:    catId,
        search:   search,
        page:     1,
        pageSize: 20,
      );
      _productList = result['products'] as List<ProductModel>;
      _hasMore     = result['has_next']  as bool;
    } catch (e) {
      _productList  = [];
      _errorMessage = e.toString();
      print('getProducts error: $e');
    }

    _loadProduct = false;
    notifyListeners();
  }

  // ── Load next page (triggered on scroll) ───────
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _loadProduct) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result   = await _apiServices.fetchProducts(
        catId:    _activeCatId,
        search:   _activeSearch,
        page:     nextPage,
        pageSize: 20,
      );

      _productList.addAll(result['products'] as List<ProductModel>);
      _hasMore     = result['has_next'] as bool;
      _currentPage = nextPage;
    } catch (e) {
      _errorMessage = e.toString();
      print('loadMore error: $e');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Create ─────────────────────────────────────
  Future<bool> createProduct(
      BuildContext context, {
        required int catId,
        required String prodName,
        String? sizes,
        bool isFreeSize   = false,
        double? fixPrice,
        File? prodImage,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.createProduct(
        catId:      catId,
        prodName:   prodName,
        sizes:      sizes,
        isFreeSize: isFreeSize,
        fixPrice:   fixPrice,
        prodImage:  prodImage,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        // Re-fetch page 1 with same active filters
        await getProducts(context, catId: catId);
        return true;
      }

      _errorMessage = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      print('createProduct error: $e');
      notifyListeners();
      return false;
    }
  }

  // ── Update ─────────────────────────────────────
  Future<bool> updateProduct(
      BuildContext context, {
        required int prodId,
        int?    catId,
        String? prodName,
        String? sizes,
        bool?   isFreeSize,
        double? fixPrice,
        bool?   isActive,
        File?   prodImage,
        bool    removeImage = false,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.updateProduct(
        prodId:      prodId,
        catId:       catId,
        prodName:    prodName,
        sizes:       sizes,
        isFreeSize:  isFreeSize,
        fixPrice:    fixPrice,
        isActive:    isActive,
        prodImage:   prodImage,
        removeImage: removeImage,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        final updated = ProductModel.fromJson(response['data']);
        final index   = _productList.indexWhere((p) => p.prodId == prodId);
        if (index != -1) {
          _productList[index] = updated;
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

  // ── Delete ─────────────────────────────────────
  Future<bool> deleteProduct(BuildContext context, int prodId) async {
    _errorMessage = null;

    try {
      final response = await _apiServices.deleteProduct(prodId);

      if (response['status'] == true) {
        _productList.removeWhere((p) => p.prodId == prodId);
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