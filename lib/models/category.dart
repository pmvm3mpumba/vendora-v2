/// Document Firestore `categories/{id}`.
class Category {
  final String id;
  final String name;
  final String icon; // emoji
  final int order;

  const Category({
    required this.id,
    required this.name,
    this.icon = '🏷️',
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {'name': name, 'icon': icon, 'order': order};

  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
        id: id,
        name: map['name'] ?? '',
        icon: map['icon'] ?? '🏷️',
        order: map['order'] ?? 0,
      );
}
