class DocumentType {
  final String id;
  final String name;
  final double price;
  final bool active;

  DocumentType({
    required this.id,
    required this.name,
    required this.price,
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'active': active,
      };

  factory DocumentType.fromMap(String id, Map<String, dynamic> map) =>
      DocumentType(
        id: id,
        name: map['name'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        active: map['active'] ?? true,
      );
}