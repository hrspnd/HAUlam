class MenuItem {
  final String id;
  final String name;
  final String imagePath;
  final bool isAvailable;
  final double price;
  final String description;
  final List<String> tags;

  MenuItem({
    required this.id,
    required this.name,
    required this.imagePath,
    this.isAvailable = true,
    this.price = 0.0,
    this.description = '',
    this.tags = const [],
  });

  // Convert backend data to object
  factory MenuItem.fromMap(Map<String, dynamic> data, String id) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      imagePath: data['imagePath'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert object to backend map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imagePath': imagePath,
      'isAvailable': isAvailable,
      'price': price,
      'description': description,
      'tags': tags,
    };
  }
}
