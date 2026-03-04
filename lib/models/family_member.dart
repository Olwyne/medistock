class FamilyMember {
  final int id;
  final String name;
  final int sortOrder;

  const FamilyMember({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
      };

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
        id: m['id'] as int,
        name: m['name'] as String,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}
