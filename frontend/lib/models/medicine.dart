// lib/models/medicine.dart
class Medicine {
  final String? id;
  final String medicineName;
  final String unit;
  final double price;
  final int stockQuantity;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Medicine({
    this.id,
    required this.medicineName,
    required this.unit,
    required this.price,
    this.stockQuantity = 0,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'],
      medicineName: json['medicineName'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      description: json['description'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'medicineName': medicineName,
      'unit': unit,
      'price': price,
      'stockQuantity': stockQuantity,
      if (description != null) 'description': description,
    };
  }

  Medicine copyWith({
    String? id,
    String? medicineName,
    String? unit,
    double? price,
    int? stockQuantity,
    String? description,
  }) {
    return Medicine(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
    );
  }

  bool get isLowStock => stockQuantity < 10;
  bool get isOutOfStock => stockQuantity == 0;
}