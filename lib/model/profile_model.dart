class ProfileModel {
  final int id;
  final String name;
  final String username;
  final String contactNo;
  final String? email;
  final String role;
  final bool isActive;
  final String? createdAt;
  final ShopModel? shop;

  ProfileModel({
    required this.id,
    required this.name,
    required this.username,
    required this.contactNo,
    this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.shop,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id:        json['id'] as int,
      name:      json['name']?.toString() ?? '',
      username:  json['username']?.toString() ?? '',
      contactNo: json['contact_no']?.toString() ?? '',
      email:     json['email']?.toString(),
      role:      json['role']?.toString() ?? 'EMPLOYEE',
      isActive:  json['is_active'] ?? true,
      createdAt: json['created_at']?.toString(),
      shop:      json['shop'] != null
          ? ShopModel.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ShopModel {
  final int shId;
  final String shName;
  final String shContactNo;
  final String? shEmail;
  final String shAddress;
  final String? gstNo;
  final bool isActive;
  final String? createdAt;

  ShopModel({
    required this.shId,
    required this.shName,
    required this.shContactNo,
    this.shEmail,
    required this.shAddress,
    this.gstNo,
    required this.isActive,
    this.createdAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      shId:        json['sh_id'] as int,
      shName:      json['sh_name']?.toString() ?? '',
      shContactNo: json['sh_contact_no']?.toString() ?? '',
      shEmail:     json['sh_email']?.toString(),
      shAddress:   json['sh_address']?.toString() ?? '',
      gstNo:       json['gst_no']?.toString(),
      isActive:    json['is_active'] ?? true,
      createdAt:   json['created_at']?.toString(),
    );
  }
}