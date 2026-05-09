class EmployeeModel {
  final int id;
  final String name;
  final String username;
  final String contactNo;
  final String? email;
  final String role;
  final bool isActive;
  final int? createdBy;
  final String? createdAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.username,
    required this.contactNo,
    this.email,
    required this.role,
    required this.isActive,
    this.createdBy,
    this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id:        json['id'] as int,
      name:      json['name']?.toString() ?? '',
      username:  json['username']?.toString() ?? '',
      contactNo: json['contact_no']?.toString() ?? '',
      email:     json['email']?.toString(),
      role:      json['role']?.toString() ?? 'EMPLOYEE',
      isActive:  json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: json['created_at']?.toString(),
    );
  }
}