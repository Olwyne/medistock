import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyCurrentFamilyId = 'current_family_id';

/// Service d'authentification (Firebase Auth) et de gestion de la famille courante (Firestore).
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
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

  /// Liste des familles de l'utilisateur (id, name).
  Future<List<Map<String, dynamic>>> getFamilies() async {
    if (currentUser == null) return [];
    final snap = await _db.collectionGroup('acl').where('uid', isEqualTo: currentUser!.uid).get();
    final result = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final familyRef = doc.reference.parent.parent!;
      final familyDoc = await familyRef.get();
      result.add({
        'id': familyRef.id,
        'name': familyDoc.data()?['name'] as String? ?? '',
      });
    }
    return result;
  }

  /// Nom affiché de l'utilisateur, à défaut la partie locale de son email.
  String _selfDisplayName(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email ?? '';
    final local = email.split('@').first;
    return local.isEmpty ? 'Moi' : local[0].toUpperCase() + local.substring(1);
  }

  /// Crée une nouvelle famille, y ajoute l'utilisateur comme owner et comme membre par défaut.
  Future<String> createFamily({String? name}) async {
    final user = currentUser;
    if (user == null) throw Exception('Non connecté');
    final familyRef = _db.collection('families').doc();
    final batch = _db.batch();
    batch.set(familyRef, {'name': name ?? 'Ma famille', 'createdAt': Timestamp.now()});
    batch.set(familyRef.collection('acl').doc(user.uid), {'uid': user.uid, 'role': 'owner'});
    batch.set(familyRef.collection('members').doc(user.uid), {'name': _selfDisplayName(user), 'sortOrder': 0});
    await batch.commit();
    await setCurrentFamilyId(familyRef.id);
    return familyRef.id;
  }

  /// Rejoint une famille par son ID (partagé hors app), et s'y ajoute comme membre par défaut.
  Future<void> joinFamily(String familyId) async {
    final user = currentUser;
    if (user == null) throw Exception('Non connecté');
    final familyRef = _db.collection('families').doc(familyId);
    final batch = _db.batch();
    batch.set(familyRef.collection('acl').doc(user.uid), {'uid': user.uid, 'role': 'member'});
    batch.set(familyRef.collection('members').doc(user.uid), {'name': _selfDisplayName(user), 'sortOrder': 0});
    await batch.commit();
    await setCurrentFamilyId(familyId);
  }

  /// Met à jour le prénom (displayName) de l'utilisateur connecté.
  Future<void> updateDisplayName(String name) async {
    await currentUser?.updateDisplayName(name);
  }

  /// Garantit que l'utilisateur connecté a bien un profil membre dans ce foyer
  /// (rattrape les foyers créés avant l'ajout automatique du créateur comme membre).
  Future<void> ensureSelfMember(String familyId) async {
    final user = currentUser;
    if (user == null) return;
    final memberRef = _db.collection('families').doc(familyId).collection('members').doc(user.uid);
    final doc = await memberRef.get();
    if (!doc.exists) {
      await memberRef.set({'name': _selfDisplayName(user), 'sortOrder': 0});
    }
  }

  /// Déconnexion et effacement de la famille courante.
  Future<void> signOut() async {
    await setCurrentFamilyId(null);
    await _auth.signOut();
  }

  /// Connexion email / mot de passe.
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Inscription email / mot de passe.
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Écoute les changements d'auth (connexion / déconnexion).
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
