class MedicalRecord {
  final String? id;
  final String patientId;
  final DateTime visitDate;
  final String symptoms;
  final String? diagnosis;
  final String? doctorName;
  final String? roomNumber;
  final List<ServiceItem> services;
  final List<PrescriptionItem> prescriptions;
  final double discount;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Populated fields
  final PatientInfo? patientInfo;

  MedicalRecord({
    this.id,
    required this.patientId,
    required this.visitDate,
    required this.symptoms,
    this.diagnosis,
    this.doctorName,
    this.roomNumber,
    this.services = const [],
    this.prescriptions = const [],
    this.discount = 0,
    this.notes,
    this.status = 'Đang khám',
    this.createdAt,
    this.updatedAt,
    this.patientInfo,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['_id'],
      patientId: json['patientId'] is String 
          ? json['patientId'] 
          : json['patientId']['_id'],
      visitDate: DateTime.parse(json['visitDate']),
      symptoms: json['symptoms'] ?? '',
      diagnosis: json['diagnosis'],
      doctorName: json['doctorName'],
      roomNumber: json['roomNumber'],
      services: (json['services'] as List?)
          ?.map((s) => ServiceItem.fromJson(s))
          .toList() ?? [],
      prescriptions: (json['prescriptions'] as List?)
          ?.map((p) => PrescriptionItem.fromJson(p))
          .toList() ?? [],
      discount: (json['discount'] ?? 0).toDouble(),
      notes: json['notes'],
      status: json['status'] ?? 'Đang khám',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      patientInfo: json['patientId'] is Map 
          ? PatientInfo.fromJson(json['patientId']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (doctorName != null) 'doctorName': doctorName,
      if (roomNumber != null) 'roomNumber': roomNumber,
      'services': services.map((s) => s.toJson()).toList(),
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'discount': discount,
      if (notes != null) 'notes': notes,
      'status': status,
    };
  }

  double get totalServiceCost {
    return services.fold(0, (sum, item) => sum + item.price);
  }

  double get totalMedicineCost {
    return prescriptions.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get subtotal {
    return totalServiceCost + totalMedicineCost;
  }

  double get totalAmount {
    return subtotal - discount;
  }
}

class ServiceItem {
  final String? serviceId;
  final String serviceName;
  final double price;

  ServiceItem({
    this.serviceId,
    required this.serviceName,
    required this.price,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serviceId != null) 'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
    };
  }
}

class PrescriptionItem {
  final String? medicineId;
  final String medicineName;
  final int quantity;
  final String? unit;
  final double price;
  final String? dosage;

  PrescriptionItem({
    this.medicineId,
    required this.medicineName,
    required this.quantity,
    this.unit,
    required this.price,
    this.dosage,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicineId: json['medicineId'],
      medicineName: json['medicineName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
      price: (json['price'] ?? 0).toDouble(),
      dosage: json['dosage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (medicineId != null) 'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      'price': price,
      if (dosage != null) 'dosage': dosage,
    };
  }

  double get totalPrice => price * quantity;
}

class PatientInfo {
  final String id;
  final String fullName;
  final String phone;
  final String? patientType;

  PatientInfo({
    required this.id,
    required this.fullName,
    required this.phone,
    this.patientType,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      patientType: json['patientType'],
    );
  }
}