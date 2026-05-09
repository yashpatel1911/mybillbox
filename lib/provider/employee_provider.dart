import 'package:flutter/material.dart';
import '../api_service/api_service.dart';
import '../model/employee_model.dart';

class EmployeeProvider with ChangeNotifier {
  List<EmployeeModel> _employeeList = [];
  bool _loadEmployee = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final ServiceDB _apiServices = ServiceDB();

  List<EmployeeModel> get employeeList  => _employeeList;
  bool get loadEmployee                 => _loadEmployee;
  bool get isSubmitting                 => _isSubmitting;
  String? get errorMessage              => _errorMessage;

  // ── GET ───────────────────────────────────────────
  Future<void> getEmployees(BuildContext context) async {
    _loadEmployee = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _employeeList = await _apiServices.fetchEmployees();
    } catch (e) {
      _employeeList = [];
      _errorMessage = e.toString();
    }

    _loadEmployee = false;
    notifyListeners();
  }

  // ── ADD ───────────────────────────────────────────
  Future<bool> addEmployee(
      BuildContext context, {
        required String name,
        required String username,
        required String contactNo,
        String? email,
        required String password,
        required String role,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.addEmployee(
        name:      name,
        username:  username,
        contactNo: contactNo,
        email:     email,
        password:  password,
        role:      role,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        _employeeList.insert(0, EmployeeModel.fromJson(response['data']));
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

  // ── UPDATE ────────────────────────────────────────
  Future<bool> updateEmployee(
      BuildContext context, {
        required int empId,
        required String name,
        required String contactNo,
        String? email,
        required String role,
        required bool isActive,
      }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiServices.updateEmployee(
        empId:     empId,
        name:      name,
        contactNo: contactNo,
        email:     email,
        role:      role,
        isActive:  isActive,
      );

      _isSubmitting = false;

      if (response['status'] == true) {
        final updated = EmployeeModel.fromJson(response['data']);
        final index   = _employeeList.indexWhere((e) => e.id == empId);
        if (index != -1) {
          _employeeList[index] = updated;
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

  // ── DELETE ────────────────────────────────────────
  Future<bool> deleteEmployee(BuildContext context, int empId) async {
    _errorMessage = null;

    try {
      final response = await _apiServices.deleteEmployee(empId);

      if (response['status'] == true) {
        _employeeList.removeWhere((e) => e.id == empId);
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