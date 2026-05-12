class ExpenseCategoryModel {
  final int expCatId;
  final String expCatName;
  final String? expCatDescription;
  final int? shopId;
  final String? shopName;
  final bool isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  ExpenseCategoryModel({
    required this.expCatId,
    required this.expCatName,
    this.expCatDescription,
    this.shopId,
    this.shopName,
    required this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      expCatId: json['exp_cat_id'] as int,
      expCatName: json['exp_cat_name']?.toString() ?? '',
      expCatDescription: json['exp_cat_description']?.toString(),
      shopId: json['shop_id'],
      shopName: json['shop_name']?.toString(),
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}