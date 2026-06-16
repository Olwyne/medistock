class Place {
  final String id;
  final String name;

  const Place({required this.id, required this.name});

  Map<String, dynamic> toFirestore() => {'name': name};

  factory Place.fromFirestore(String id, Map<String, dynamic> data) => Place(
        id: id,
        name: data['name'] as String,
      );
}
