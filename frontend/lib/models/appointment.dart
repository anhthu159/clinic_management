class Appointment {
  final String? id;
  final String patientId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String? doctorName;
  final String? roomNumber;
  final String? serviceType;
  final String? reason;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Populated fields
  final PatientInfo? patientInfo;

  Appointment({
    this.id,
    required this.patientId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.doctorName,
    this.roomNumber,
    this.serviceType,
    this.reason,
    this.status = 'Chờ khám',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.patientInfo,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'],
      patientId: json['patientId'] is String 
          ? json['patientId'] 
          : json['patientId']['_id'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      appointmentTime: json['appointmentTime'] ?? '',
      doctorName: json['doctorName'],
      roomNumber: json['roomNumber'],
      serviceType: json['serviceType'],
      reason: json['reason'],
      status: json['status'] ?? 'Chờ khám',
      notes: json['notes'],
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
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      if (doctorName != null) 'doctorName': doctorName,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (serviceType != null) 'serviceType': serviceType,
      if (reason != null) 'reason': reason,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? doctorName,
    String? roomNumber,
    String? serviceType,
    String? reason,
    String? status,
    String? notes,
    PatientInfo? patientInfo,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      doctorName: doctorName ?? this.doctorName,
      roomNumber: roomNumber ?? this.roomNumber,
      serviceType: serviceType ?? this.serviceType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      patientInfo: patientInfo ?? this.patientInfo,
    );
  }
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