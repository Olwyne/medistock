import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env_config.dart';

const _keyCurrentFamilyId = 'current_family_id';

/// Service d'authentification et de gestion de la famille courante.
class AuthService {
  AuthService() : _client = EnvConfig.isConfigured ? Supabase.instance.client : null;

  final SupabaseClient? _client;

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  bool get isSignedIn => currentUser != null;

  /// Récupère l'ID de la famille courante (stocké localement).
  static Future<String?> getCurrentFamilyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentFamilyId);
  }

  /// Enregistre la famille courante.
  static Future<void> setCurrentFamilyId(String? familyId) async {
    final prefs = await SharedPreferences.getInstance();
    if (familyId == null) {
      await prefs.remove(_keyCurrentFamilyId);
    } else {
      await prefs.setString(_keyCurrentFamilyId, familyId);
    }
  }

  /// Vérifie si l'utilisateur a au moins une famille (présence dans family_users).
  Future<bool> hasFamily() async {
    if (_client == null || currentUser == null) return false;
    final res = await _client
        .from('family_users')
        .select('id')
        .eq('user_id', currentUser!.id)
        .limit(1)
        .maybeSingle();
    return res != null;
  }

  /// Liste des familles de l'utilisateur (id, name).
  Future<List<Map<String, dynamic>>> getFamilies() async {
    if (_client == null || currentUser == null) return [];
    final list = await _client
        .from('family_users')
        .select('family_id, families(id, name)')
        .eq('user_id', currentUser!.id);
    final result = <Map<String, dynamic>>[];
    for (final row in list) {
      final fam = row['families'];
      if (fam is Map<String, dynamic>) {
        result.add({
          'id': fam['id'],
          'name': fam['name'] as String? ?? '',
        });
      }
    }
    return result;
  }

  /// Crée une nouvelle famille et y ajoute l'utilisateur comme owner.
  Future<String> createFamily({String? name}) async {
    if (_client == null || currentUser == null) throw Exception('Non connecté');
    final family = await _client.from('families').insert({
      'name': name ?? 'Ma famille',
    }).select('id').single();
    final familyId = family['id'] as String;
    await _client.from('family_users').insert({
      'family_id': familyId,
      'user_id': currentUser!.id,
      'role': 'owner',
    });
    await setCurrentFamilyId(familyId);
    return familyId;
  }

  /// Rejoint une famille par son ID (si l'utilisateur a été invité ou si lien public).
  /// Pour l'instant on suppose que l'utilisateur fournit l'UUID de la famille (partagé hors app).
  Future<void> joinFamily(String familyId) async {
    if (_client == null || currentUser == null) throw Exception('Non connecté');
    await _client.from('family_users').insert({
      'family_id': familyId,
      'user_id': currentUser!.id,
      'role': 'member',
    });
    await setCurrentFamilyId(familyId);
  }

  /// Déconnexion et effacement de la famille courante.
  Future<void> signOut() async {
    await setCurrentFamilyId(null);
    if (_client != null) await _client.auth.signOut();
  }

  /// Connexion email / mot de passe.
  Future<void> signIn(String email, String password) async {
    if (_client == null) throw StateError('Supabase non configuré');
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Inscription email / mot de passe.
  Future<void> signUp(String email, String password) async {
    if (_client == null) throw StateError('Supabase non configuré');
    await _client.auth.signUp(email: email, password: password);
  }

  /// Écoute les changements d'auth (connexion / déconnexion).
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();
}
