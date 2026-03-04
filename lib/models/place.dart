class Place {
  final int id;
  final String name;

  const Place({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Place.fromMap(Map<String, dynamic> m) => Place(
        id: m['id'] as int,
        name: m['name'] as String,
      );
}
