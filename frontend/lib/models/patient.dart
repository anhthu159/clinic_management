class Patient {
  final String? id;
  final String fullName;
  final String phone;
  final DateTime dateOfBirth;
  final String? address;
  final String? gender;
  final String? idCard;
  final String? email;
  final String patientType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Patient({
    this.id,
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
    this.address,
    this.gender,
    this.idCard,
    this.email,
    this.patientType = 'Thường',
    this.createdAt,
    this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'],
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      address: json['address'],
      gender: json['gender'],
      idCard: json['idCard'],
      email: json['email'],
      patientType: json['patientType'] ?? 'Thường',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'fullName': fullName,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      if (address != null) 'address': address,
      if (gender != null) 'gender': gender,
      if (idCard != null) 'idCard': idCard,
      if (email != null) 'email': email,
      'patientType': patientType,
    };
  }

  Patient copyWith({
    String? id,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? gender,
    String? idCard,
    String? email,
    String? patientType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      idCard: idCard ?? this.idCard,
      email: email ?? this.email,
      patientType: patientType ?? this.patientType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}