class FamilyMember {
  final String id;
  final String name;
  final int sortOrder;

  const FamilyMember({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'sortOrder': sortOrder,
      };

  factory FamilyMember.fromFirestore(String id, Map<String, dynamic> data) => FamilyMember(
        id: id,
        name: data['name'] as String,
        sortOrder: data['sortOrder'] as int? ?? 0,
      );
}
