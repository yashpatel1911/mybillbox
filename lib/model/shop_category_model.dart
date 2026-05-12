class ShopCategoryModel {
  final int catId;
  final String catName;
  final String? catDescription;

  ShopCategoryModel({
    required this.catId,
    required this.catName,
    this.catDescription,
  });

  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) =>
      ShopCategoryModel(
        catId: json['cat_id'] as int,
        catName: json['cat_name']?.toString() ?? '',
        catDescription: json['cat_description']?.toString(),
      );
}
