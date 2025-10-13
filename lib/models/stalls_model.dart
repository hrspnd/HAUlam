class Stall {
  final String id;
  final String imagePath;
  final String title;
  final String status;
  final bool isFavorited;
  final String location;
  final String stallName; 

  Stall({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.status,
    this.isFavorited = false,
    required this.location,
    required this.stallName, 
  });

  factory Stall.fromMap(Map<String, dynamic> data, String id) {
    return Stall(
      id: id,
      imagePath: data['imagePath'] ?? '',
      title: data['title'] ?? '',
      status: data['status'] ?? 'Closed',
      isFavorited: data['isFavorited'] ?? false,
      location: data['location'] ?? '',
      stallName: data['stallName'] ?? '', 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'title': title,
      'status': status,
      'isFavorited': isFavorited,
      'location': location,
      'stallName': stallName, 
    };
  }

  Stall copyWith({
    String? id,
    String? imagePath,
    String? title,
    String? status,
    bool? isFavorited,
    String? location,
    String? stallName, 
  }) {
    return Stall(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      status: status ?? this.status,
      isFavorited: isFavorited ?? this.isFavorited,
      location: location ?? this.location,
      stallName: stallName ?? this.stallName,
    );
  }
}
