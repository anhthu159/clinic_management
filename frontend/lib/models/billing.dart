class Billing {
  final String? id;
  final String medicalRecordId;
  final String patientId;
  final List<ServiceCharge> serviceCharges;
  final List<MedicineCharge> medicineCharges;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? paidDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Populated fields
  final PatientInfo? patientInfo;
  final MedicalRecordInfo? medicalRecordInfo;

  Billing({
    this.id,
    required this.medicalRecordId,
    required this.patientId,
    required this.serviceCharges,
    required this.medicineCharges,
    required this.subtotal,
    this.discount = 0,
    required this.totalAmount,
    this.paymentStatus = 'Chưa thanh toán',
    this.paymentMethod,
    this.paidDate,
    this.createdAt,
    this.updatedAt,
    this.patientInfo,
    this.medicalRecordInfo,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      id: json['_id'],
      medicalRecordId: json['medicalRecordId'] is String 
          ? json['medicalRecordId'] 
          : json['medicalRecordId']['_id'],
      patientId: json['patientId'] is String 
          ? json['patientId'] 
          : json['patientId']['_id'],
      serviceCharges: (json['serviceCharges'] as List?)
          ?.map((s) => ServiceCharge.fromJson(s))
          .toList() ?? [],
      medicineCharges: (json['medicineCharges'] as List?)
          ?.map((m) => MedicineCharge.fromJson(m))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'Chưa thanh toán',
      paymentMethod: json['paymentMethod'],
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      patientInfo: json['patientId'] is Map 
          ? PatientInfo.fromJson(json['patientId']) 
          : null,
      medicalRecordInfo: json['medicalRecordId'] is Map 
          ? MedicalRecordInfo.fromJson(json['medicalRecordId']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'medicalRecordId': medicalRecordId,
      'patientId': patientId,
      'serviceCharges': serviceCharges.map((s) => s.toJson()).toList(),
      'medicineCharges': medicineCharges.map((m) => m.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paidDate != null) 'paidDate': paidDate!.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'Đã thanh toán';
  bool get isPartiallyPaid => paymentStatus == 'Thanh toán một phần';
  bool get isUnpaid => paymentStatus == 'Chưa thanh toán';
}

class ServiceCharge {
  final String serviceName;
  final double price;
  final int quantity;

  ServiceCharge({
    required this.serviceName,
    required this.price,
    this.quantity = 1,
  });

  factory ServiceCharge.fromJson(Map<String, dynamic> json) {
    return ServiceCharge(
      serviceName: json['serviceName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceName': serviceName,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;
}

class MedicineCharge {
  final String medicineName;
  final double price;
  final int quantity;

  MedicineCharge({
    required this.medicineName,
    required this.price,
    required this.quantity,
  });

  factory MedicineCharge.fromJson(Map<String, dynamic> json) {
    return MedicineCharge(
      medicineName: json['medicineName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;
}

class PatientInfo {
  final String id;
  final String fullName;
  final String phone;

  PatientInfo({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class MedicalRecordInfo {
  final String id;
  final DateTime visitDate;

  MedicalRecordInfo({
    required this.id,
    required this.visitDate,
  });

  factory MedicalRecordInfo.fromJson(Map<String, dynamic> json) {
    return MedicalRecordInfo(
      id: json['_id'] ?? '',
      visitDate: DateTime.parse(json['visitDate']),
    );
  }
}