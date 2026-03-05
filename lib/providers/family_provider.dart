import 'package:flutter/foundation.dart';
import '../data/database.dart';
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
    if (kIsWeb) {
      _members = [];
      _places = [];
      notifyListeners();
      return;
    }
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) {
      _members = [];
      _places = [];
      notifyListeners();
      return;
    }
    _members = await AppDatabase.getFamilyMembers(familyId: familyId);
    _places = await AppDatabase.getPlaces(familyId: familyId);
    notifyListeners();
  }

  Future<void> addMember(String name) async {
    if (kIsWeb) return;
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    final order = _members.isEmpty ? 0 : (_members.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    await AppDatabase.insertFamilyMember(FamilyMember(id: 0, name: name, sortOrder: order), familyId: familyId);
    await load();
  }

  Future<void> deleteMember(int id) async {
    if (kIsWeb) return;
    await AppDatabase.deleteFamilyMember(id);
    await load();
  }

  Future<void> addPlace(String name) async {
    if (kIsWeb) return;
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    await AppDatabase.insertPlace(Place(id: 0, name: name), familyId: familyId);
    await load();
  }

  Future<void> deletePlace(int id) async {
    if (kIsWeb) return;
    await AppDatabase.deletePlace(id);
    await load();
  }

  /// Vide les données en mémoire (après déconnexion).
  void clear() {
    _members = [];
    _places = [];
    notifyListeners();
  }
}
