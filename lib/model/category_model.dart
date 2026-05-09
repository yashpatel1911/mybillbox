class CategoryModel {
  final int catId;
  final String catName;
  final String? catImage;
  final bool isActive;
  final int? createdBy;
  final String? createdAt;

  CategoryModel({
    required this.catId,
    required this.catName,
    this.catImage,
    required this.isActive,
    this.createdBy,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      catId: json['cat_id'] as int,
      catName: json['cat_name']?.toString() ?? '',
      catImage: json['cat_image']?.toString(), // handles null safely
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: json['created_at']?.toString(),
    );
  }
}