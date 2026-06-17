import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _auth = AuthService();
    _init();
    _auth.authStateChanges.listen((_) {
      unawaited(_onAuthChange());
    });
  }

  late final AuthService _auth;
  String? _currentFamilyId;
  bool _loading = true;
  String? _error;

  bool get isSignedIn => _auth.isSignedIn;
  String? get currentFamilyId => _currentFamilyId;
  bool get hasFamily => _currentFamilyId != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;

  /// Cherche les foyers de l'utilisateur dans Firestore, avec retries : juste après
  /// signIn/signUp (ou au tout premier chargement sur réseau mobile lent), le token
  /// Firebase Auth peut ne pas encore être propagé au SDK Firestore -> permission-denied
  /// transitoire. On retente plutôt que d'abandonner silencieusement.
  Future<List<Map<String, dynamic>>> _getFamiliesWithRetry() async {
    const delays = [Duration(milliseconds: 300), Duration(milliseconds: 800), Duration(milliseconds: 1500)];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return await _auth.getFamilies();
      } catch (_) {
        if (attempt == delays.length) return [];
        await Future.delayed(delays[attempt]);
      }
    }
    return [];
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    _currentFamilyId = await AuthService.getCurrentFamilyId();
    if (isSignedIn && _currentFamilyId == null) {
      final families = await _getFamiliesWithRetry();
      if (families.isNotEmpty) {
        await AuthService.setCurrentFamilyId(families.first['id'] as String?);
        _currentFamilyId = await AuthService.getCurrentFamilyId();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _onAuthChange() async {
    _loading = true;
    notifyListeners();
    if (!_auth.isSignedIn) {
      _currentFamilyId = null;
    } else {
      _currentFamilyId = await AuthService.getCurrentFamilyId();
      if (_currentFamilyId == null) {
        final families = await _getFamiliesWithRetry();
        if (families.isNotEmpty) {
          await AuthService.setCurrentFamilyId(families.first['id'] as String?);
          _currentFamilyId = await AuthService.getCurrentFamilyId();
        }
      }
    }
    _loading = false;
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

  Future<void> signUp(String email, String password, {String? displayName}) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.signUp(email, password);
      if (displayName != null && displayName.trim().isNotEmpty) {
        await _auth.updateDisplayName(displayName.trim());
      }
      await _onAuthChange();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.updateDisplayName(name);
    notifyListeners();
  }

  /// Rattrape les foyers où l'utilisateur n'a pas (encore) de profil membre.
  Future<void> ensureSelfMember() async {
    final familyId = _currentFamilyId;
    if (familyId == null) return;
    try {
      await _auth.ensureSelfMember(familyId);
    } catch (_) {}
  }

  Future<void> signOut() async {
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
