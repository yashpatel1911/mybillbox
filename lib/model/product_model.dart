class ProductModel {
  final int prodId;
  final String prodName;
  final String? prodImage;
  final int catId;
  final String catName;
  final String? sizes;
  final bool isFreeSize;
  final double? fixPrice;
  final bool isActive;

  ProductModel({
    required this.prodId,
    required this.prodName,
    this.prodImage,
    required this.catId,
    required this.catName,
    this.sizes,
    required this.isFreeSize,
    this.fixPrice,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      prodId: json['prod_id'],
      prodName: json['prod_name'],
      prodImage: json['prod_image'],
      catId: json['category']['cat_id'],
      catName: json['category']['cat_name'],
      sizes: json['sizes'],
      isFreeSize: json['is_free_size'],
      fixPrice: json['fix_price'] != null
          ? double.tryParse(json['fix_price'].toString())
          : null,
      isActive: json['is_active'],
    );
  }
}