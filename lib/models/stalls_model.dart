/*
  File: stalls_model.dart
  Purpose: Data model for vendor stalls stored in the Supabase "Stalls" table.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

/// Model for public."Stalls"
class Stall {
  final String id;
  final String imagePath;
  final String title;
  final String status;
  final bool isFavorited;
  final String location;
  final String stallName;
  final String? openTime;  
  final String? closeTime;  

  Stall({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.status,
    this.isFavorited = false,
    required this.location,
    required this.stallName,
    this.openTime,   
    this.closeTime,  
  });

  /// Build from a Supabase row (Map)
  factory Stall.fromMap(Map<String, dynamic> data, String id) {
    return Stall(
      id: id,
      imagePath: data['imagePath'] ?? '',
      title: data['title'] ?? '',
      status: data['status'] ?? 'Closed',
      isFavorited: data['isFavorited'] ?? false,
      location: data['location'] ?? '',
      stallName: data['stallName'] ?? '',
      openTime: data['open_time'] ?? '',  
      closeTime: data['close_time'] ?? '', 
    );
  }

  /// Map for insert/update (omit id & created_at; DB sets those)
  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'title': title,
      'status': status,
      'isFavorited': isFavorited,
      'location': location,
      'stallName': stallName,
      if (openTime != null) 'open_time': openTime,   
      if (closeTime != null) 'close_time': closeTime,
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
    String? openTime,
    String? closeTime,
  }) {
    return Stall(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      status: status ?? this.status,
      isFavorited: isFavorited ?? this.isFavorited,
      location: location ?? this.location,
      stallName: stallName ?? this.stallName,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}
