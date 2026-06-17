import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../models/family_member.dart';
import '../models/place.dart';
import 'auth_provider.dart';

class FamilyProvider extends ChangeNotifier {
  FamilyProvider({AuthProvider? auth}) : _auth = auth {
    _auth?.addListener(_onAuthChanged);
  }

  final AuthProvider? _auth;

  void _onAuthChanged() {
    final auth = _auth;
    if (auth != null && !auth.isSignedIn) clear();
  }

  List<FamilyMember> _members = [];
  List<Place> _places = [];

  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Place> get places => List.unmodifiable(_places);

  Future<void> load() async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) {
      _members = [];
      _places = [];
      notifyListeners();
      return;
    }
    await _auth?.ensureSelfMember();
    _members = await FirestoreRepository.getFamilyMembers(familyId);
    _places = await FirestoreRepository.getPlaces(familyId);
    notifyListeners();
  }

  Future<void> addMember(String name) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    final order = _members.isEmpty ? 0 : (_members.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    await FirestoreRepository.insertFamilyMember(familyId, FamilyMember(id: '', name: name, sortOrder: order));
    await load();
  }

  Future<void> deleteMember(String id) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    await FirestoreRepository.deleteFamilyMember(familyId, id);
    await load();
  }

  Future<void> addPlace(String name) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    await FirestoreRepository.insertPlace(familyId, Place(id: '', name: name));
    await load();
  }

  Future<void> deletePlace(String id) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    await FirestoreRepository.deletePlace(familyId, id);
    await load();
  }

  /// Vide les données en mémoire (après déconnexion).
  void clear() {
    _members = [];
    _places = [];
    notifyListeners();
  }
}
