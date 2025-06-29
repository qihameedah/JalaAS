// lib/models/contact.dart
class Contact {
  final int? id;
  final String code;
  final String nameAr;
  final String? area;
  final String? areaName;
  final String? salesman;
  final String? streetAddress;
  final String? taxId;
  final String? phone;
  final DateTime? lastChanged;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    this.id,
    required this.code,
    required this.nameAr,
    this.area,
    this.areaName,
    this.salesman,
    this.streetAddress,
    this.taxId,
    this.phone,
    this.lastChanged,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      area: json['area'] as String?,
      areaName: json['area_name'] as String?,
      salesman: json['salesman'] as String?,
      streetAddress: json['street_address'] as String?,
      taxId: json['tax_id'] as String?,
      phone: json['phone'] as String?,
      lastChanged: json['last_changed'] != null
          ? DateTime.parse(json['last_changed'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory Contact.fromBisanJson(Map<String, dynamic> json) {
    return Contact(
      code: json['code'] as String? ?? '',
      nameAr: json['nameAR'] as String? ?? '',
      area: json['area'] as String?,
      areaName: json['area.name'] as String?,
      salesman: json['salesman'] as String?,
      streetAddress: json['streetAddress'] as String?,
      taxId: json['taxId'] as String?,
      phone: json['phone'] as String?,
      lastChanged: DateTime.now(), // Set current time for Bisan imports
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name_ar': nameAr,
      'area': area,
      'area_name': areaName,
      'salesman': salesman,
      'street_address': streetAddress,
      'tax_id': taxId,
      'phone': phone,
      'last_changed': lastChanged?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Contact copyWith({
    int? id,
    String? code,
    String? nameAr,
    String? area,
    String? areaName,
    String? salesman,
    String? streetAddress,
    String? taxId,
    String? phone,
    DateTime? lastChanged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      area: area ?? this.area,
      areaName: areaName ?? this.areaName,
      salesman: salesman ?? this.salesman,
      streetAddress: streetAddress ?? this.streetAddress,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      lastChanged: lastChanged ?? this.lastChanged,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, code: $code, nameAr: $nameAr, area: $area, salesman: $salesman)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
