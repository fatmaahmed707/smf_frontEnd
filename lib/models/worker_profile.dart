class WorkerProfile {
  final String id;
  final String fullNameAr;
  final String fullNameEn;
  final DateTime? dateOfBirth;
  final String addressAr;
  final String addressEn;
  final String phone;
  final String roleAr;
  final String roleEn;
  final String companyAr;
  final String companyEn;
  final String workLocationAr;
  final String workLocationEn;
  final String medicalConditionAr;
  final String medicalConditionEn;
  final String clinicalNotesAr;
  final String clinicalNotesEn;
  final String emergencyContactName;
  final String emergencyContactRelation;
  final String emergencyPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkerProfile({
    required this.id,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.dateOfBirth,
    required this.addressAr,
    required this.addressEn,
    required this.phone,
    required this.roleAr,
    required this.roleEn,
    required this.companyAr,
    required this.companyEn,
    required this.workLocationAr,
    required this.workLocationEn,
    required this.medicalConditionAr,
    required this.medicalConditionEn,
    required this.clinicalNotesAr,
    required this.clinicalNotesEn,
    required this.emergencyContactName,
    required this.emergencyContactRelation,
    required this.emergencyPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: (json['id'] ?? '').toString(),
      fullNameAr: (json['full_name_ar'] ?? json['fullNameAr'] ?? '').toString(),
      fullNameEn: (json['full_name_en'] ?? json['fullNameEn'] ?? '').toString(),
      dateOfBirth: _parseDate(json['date_of_birth'] ?? json['dateOfBirth']),
      addressAr: (json['address_ar'] ?? json['addressAr'] ?? '').toString(),
      addressEn: (json['address_en'] ?? json['addressEn'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      roleAr: (json['role_ar'] ?? json['roleAr'] ?? '').toString(),
      roleEn: (json['role_en'] ?? json['roleEn'] ?? '').toString(),
      companyAr: (json['company_ar'] ?? json['companyAr'] ?? '').toString(),
      companyEn: (json['company_en'] ?? json['companyEn'] ?? '').toString(),
      workLocationAr:
          (json['work_location_ar'] ?? json['workLocationAr'] ?? '').toString(),
      workLocationEn:
          (json['work_location_en'] ?? json['workLocationEn'] ?? '').toString(),
      medicalConditionAr:
          (json['medical_condition_ar'] ?? json['medicalConditionAr'] ?? '')
              .toString(),
      medicalConditionEn:
          (json['medical_condition_en'] ?? json['medicalConditionEn'] ?? '')
              .toString(),
      clinicalNotesAr:
          (json['clinical_notes_ar'] ?? json['clinicalNotesAr'] ?? '')
              .toString(),
      clinicalNotesEn:
          (json['clinical_notes_en'] ?? json['clinicalNotesEn'] ?? '')
              .toString(),
      emergencyContactName:
          (json['emergency_contact_name'] ?? json['emergencyContactName'] ?? '')
              .toString(),
      emergencyContactRelation: (json['emergency_contact_relation'] ??
              json['emergencyContactRelation'] ??
              json['emergency_contact_relationship'] ??
              '')
          .toString(),
      emergencyPhone:
          (json['emergency_phone'] ?? json['emergencyPhone'] ?? '').toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
