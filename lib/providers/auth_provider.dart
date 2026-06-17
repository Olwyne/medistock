import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _auth = AuthService();
    _auth.authStateChanges.listen((_) {
      unawaited(_onAuthChange());
    });
    // Premier chargement : lit les prefs, puis le stream déclenchera _onAuthChange
    // si un user est déjà connecté. _loading reste true jusqu'à la fin.
    _readPrefsAndWait();
  }

  late final AuthService _auth;
  String? _currentFamilyId;
  bool _loading = true;
  bool _authChangePending = false;
  String? _error;

  bool get isSignedIn => _auth.isSignedIn;
  String? get currentFamilyId => _currentFamilyId;
  bool get hasFamily => _currentFamilyId != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;

  /// Lit les prefs locales au démarrage. Si l'user n'est pas connecté, termine
  /// immédiatement. Si connecté, _onAuthChange (via le stream) complètera le chargement.
  Future<void> _readPrefsAndWait() async {
    _currentFamilyId = await AuthService.getCurrentFamilyId();
    // Si pas connecté ou familyId déjà en prefs → on peut finir ici
    // Si connecté et pas de familyId, _onAuthChange (stream) va chercher dans Firestore
    if (!isSignedIn) {
      _loading = false;
      notifyListeners();
    }
    // Si connecté : le stream authStateChanges fire immédiatement au démarrage,
    // donc _onAuthChange va prendre le relais et settera _loading = false.
  }

  Future<List<Map<String, dynamic>>> _getFamiliesWithRetry() async {
    const delays = [Duration(milliseconds: 400), Duration(milliseconds: 1000), Duration(milliseconds: 2000)];
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

  Future<void> _onAuthChange() async {
    // Guard : évite exécutions concurrentes
    if (_authChangePending) return;
    _authChangePending = true;
    _loading = true;
    notifyListeners();

    try {
      if (!_auth.isSignedIn) {
        _currentFamilyId = null;
      } else {
        _currentFamilyId = await AuthService.getCurrentFamilyId();
        if (_currentFamilyId == null) {
          final families = await _getFamiliesWithRetry();
          if (families.isNotEmpty) {
            await AuthService.setCurrentFamilyId(families.first['id'] as String?);
            _currentFamilyId = families.first['id'] as String?;
          }
        }
      }
    } finally {
      _authChangePending = false;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.signIn(email, password);
      // Le stream authStateChanges déclenche _onAuthChange automatiquement.
      // On attend qu'il se termine pour que le UI soit cohérent.
      await _waitForAuthChange();
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
      await _waitForAuthChange();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Attend que _onAuthChange (déclenché par le stream) ait terminé.
  Future<void> _waitForAuthChange() async {
    // Petit délai pour laisser le stream fire et _onAuthChange démarrer
    await Future.delayed(const Duration(milliseconds: 100));
    // Puis attend la fin
    while (_authChangePending) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.updateDisplayName(name);
    notifyListeners();
  }

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
