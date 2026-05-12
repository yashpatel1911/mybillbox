import 'package:flutter/material.dart';
import '../../api_service/api_service.dart';
import '../../model/expense/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  List<ExpenseModel> _expenseList = [];
  ExpenseSummary _summary = ExpenseSummary.empty();
  bool _loadExpenses = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _currentFilter = 'overall'; // 'today' | 'overall'

  final ServiceDB _apiServices = ServiceDB();

  List<ExpenseModel> get expenseList => _expenseList;
  ExpenseSummary get summary => _summary;
  bool get loadExpenses => _loadExpenses;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  // ── Fetch expenses ──
  Future<void> getExpenses(
      BuildContext context, {
        String filter = 'overall',
        String? search,
        int? expCatId,
        String? paymentMethod,
      }) async {
    _loadExpenses = true;
    _errorMessage = null;
    _currentFilter = filter;
    notifyListeners();

    try {
      final response = await _apiServices.fetchExpenses(
        filter: filter,
        search: search,
        expCatId: expCatId,
        paymentMethod: paymentMethod,
      );

      if (response['status'] == true) {
        _expenseList = (response['data'] as List)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _summary = response['summary'] != null
            ? ExpenseSummary.fromJson(response['summary'])
            : ExpenseSummary.empty();
      } else {
        _expenseList = [];
        _summary = ExpenseSummary.empty();
        _errorMessage = response['message'];
      }
    } catch (e) {
      _expenseList = [];
      _summary = ExpenseSummary.empty();
      _errorMessage = e.toString();
    }

    _loadExpenses = false;
    notifyListeners();
  }

  // ── Create ──
  Future<bool> createExpense(
      BuildContext context, {
        String? partyName,
        required int expCatId,
        required double amount,
        required String paidOn,
        required String paymentMethod,
        String? notes,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.createExpense(
        partyName: partyName,
        expCatId: expCatId,
        amount: amount,
        paidOn: paidOn,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        // refresh list to keep summary accurate
        await getExpenses(context, filter: _currentFilter);
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
  Future<bool> updateExpense(
      BuildContext context, {
        required int expId,
        String? partyName,
        int? expCatId,
        double? amount,
        String? paidOn,
        String? paymentMethod,
        String? notes,
        bool? isActive,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.updateExpense(
        expId: expId,
        partyName: partyName,
        expCatId: expCatId,
        amount: amount,
        paidOn: paidOn,
        paymentMethod: paymentMethod,
        notes: notes,
        isActive: isActive,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        await getExpenses(context, filter: _currentFilter);
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
  Future<bool> deleteExpense(BuildContext context, int expId) async {
    _errorMessage = null;
    try {
      final response = await _apiServices.deleteExpense(expId);
      if (response['status'] == true) {
        _expenseList.removeWhere((e) => e.expId == expId);
        notifyListeners();
        // refresh summary
        await getExpenses(context, filter: _currentFilter);
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