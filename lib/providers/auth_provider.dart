import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/env_config.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _auth = AuthService();
    _init();
    _auth.authStateChanges.listen((_) {
      _onAuthChange();
    });
  }

  late final AuthService _auth;
  String? _currentFamilyId;
  bool _loading = true;
  String? _error;

  bool get isConfigured => EnvConfig.isConfigured;
  bool get isSignedIn => _auth.isSignedIn;
  String? get currentFamilyId => _currentFamilyId;
  bool get hasFamily => _currentFamilyId != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get userEmail => _auth.currentUser?.email;

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    _currentFamilyId = await AuthService.getCurrentFamilyId();
    if (isSignedIn && _currentFamilyId == null) {
      final hasFam = await _auth.hasFamily();
      if (hasFam) {
        final families = await _auth.getFamilies();
        if (families.isNotEmpty) {
          await AuthService.setCurrentFamilyId(families.first['id'] as String?);
          _currentFamilyId = await AuthService.getCurrentFamilyId();
        }
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _onAuthChange() async {
    if (!_auth.isSignedIn) {
      _currentFamilyId = null;
    } else {
      _currentFamilyId = await AuthService.getCurrentFamilyId();
      if (_currentFamilyId == null) {
        final families = await _auth.getFamilies();
        if (families.isNotEmpty) {
          await AuthService.setCurrentFamilyId(families.first['id'] as String?);
          _currentFamilyId = await AuthService.getCurrentFamilyId();
        }
      }
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.signIn(email, password);
      await _onAuthChange();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.signUp(email, password);
      await _onAuthChange();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final familyId = _currentFamilyId;
    await SyncService.clearLocalFamilyData(familyId);
    await _auth.signOut();
    _currentFamilyId = null;
    _error = null;
    notifyListeners();
  }

  Future<String> createFamily({String? name}) async {
    _error = null;
    notifyListeners();
    try {
      final id = await _auth.createFamily(name: name);
      _currentFamilyId = id;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> joinFamily(String familyId) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.joinFamily(familyId);
      _currentFamilyId = await AuthService.getCurrentFamilyId();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
