/*
  File: menu_item.dart
  Purpose: Data model for dishes stored in the Supabase "Dishes" table.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

/// Model for public."Dishes"
class MenuItem {
  final String id;          
  final String? stallId;      
  final String dishName;        
  final String? description; 
  final double price;            
  final String? imageUrl;       
  final bool available;          
  final DateTime createdAt;     

  MenuItem({
    required this.id,
    required this.stallId,
    required this.dishName,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.available,
    required this.createdAt,
  });

  /// Build from a Supabase row (Map)
  factory MenuItem.fromMap(Map<String, dynamic> data) {
    final created = data['created_at'];
    return MenuItem(
      id: data['id'] as String,
      stallId: data['stall_id'] as String?,
      dishName: (data['dish_name'] ?? '') as String,
      description: data['description'] as String?,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : double.tryParse('${data['price']}') ?? 0.0,
      imageUrl: data['image_url'] as String?,
      available: (data['available'] as bool?) ?? true,
      createdAt: created is String
          ? DateTime.parse(created)
          : (created is DateTime ? created : DateTime.now()),
    );
  }

  /// Map for insert/update (omit id & created_at; DB sets those)
  Map<String, dynamic> toMap() {
    return {
      'stall_id': stallId,
      'dish_name': dishName,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'available': available,
    };
  }

  MenuItem copyWith({
    String? id,
    String? stallId,
    String? dishName,
    String? description,
    double? price,
    String? imageUrl,
    bool? available,
    DateTime? createdAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      stallId: stallId ?? this.stallId,
      dishName: dishName ?? this.dishName,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
