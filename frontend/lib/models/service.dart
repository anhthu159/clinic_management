// lib/models/service.dart
class Service {
  final String? id;
  final String serviceName;
  final String? description;
  final double price;
  final String? department;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    this.id,
    required this.serviceName,
    this.description,
    required this.price,
    this.department,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'],
      serviceName: json['serviceName'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      department: json['department'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'serviceName': serviceName,
      if (description != null) 'description': description,
      'price': price,
      if (department != null) 'department': department,
      'isActive': isActive,
    };
  }

  Service copyWith({
    String? id,
    String? serviceName,
    String? description,
    double? price,
    String? department,
    bool? isActive,
  }) {
    return Service(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      description: description ?? this.description,
      price: price ?? this.price,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
    );
  }
}

