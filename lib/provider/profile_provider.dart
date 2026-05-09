import 'package:flutter/material.dart';
import '../api_service/api_service.dart';
import '../model/profile_model.dart';

class ProfileProvider with ChangeNotifier {
  ProfileModel? _profile;
  bool _loading = true;
  String? _errorMessage;

  final ServiceDB _apiServices = ServiceDB();

  ProfileModel? get profile => _profile;

  bool get loading => _loading;

  String? get errorMessage => _errorMessage;

  // ── GET PROFILE ───────────────────────────────────
  Future<void> getProfile() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiServices.fetchMyProfile();
    } catch (e) {
      _profile = null;
      _errorMessage = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ── CLEAR (on logout) ─────────────────────────────
  void clear() {
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────
  // 3. PROVIDER — add this method to ProfileProvider
  // ──────────────────────────────────────────────────

  Future<({bool ok, String message})> changePassword({
    String? existingPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiServices.changePassword(
        existingPassword: existingPassword,
        newPassword: newPassword,
      );

      // Backend returns 'status': 'success' on success, just 'message' on errors
      final ok = response['status'] == 'success';
      final msg =
          response['message']?.toString() ??
          (ok ? 'Password changed successfully' : 'Failed to change password');
      return (ok: ok, message: msg);
    } catch (e) {
      return (ok: false, message: e.toString());
    }
  }
}
