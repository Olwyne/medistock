import 'package:flutter/foundation.dart';
import '../data/database.dart';
import '../models/family_member.dart';
import '../models/place.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyMember> _members = [];
  List<Place> _places = [];

  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Place> get places => List.unmodifiable(_places);

  Future<void> load() async {
    _members = await AppDatabase.getFamilyMembers();
    _places = await AppDatabase.getPlaces();
    notifyListeners();
  }

  Future<void> addMember(String name) async {
    final order = _members.isEmpty ? 0 : (_members.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    await AppDatabase.insertFamilyMember(FamilyMember(id: 0, name: name, sortOrder: order));
    await load();
  }

  Future<void> deleteMember(int id) async {
    await AppDatabase.deleteFamilyMember(id);
    await load();
  }

  Future<void> addPlace(String name) async {
    await AppDatabase.insertPlace(Place(id: 0, name: name));
    await load();
  }

  Future<void> deletePlace(int id) async {
    await AppDatabase.deletePlace(id);
    await load();
  }
}
