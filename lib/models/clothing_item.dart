import 'dart:io';

class ClothingItem {
  final String? id;
  final String category;
  final String description;
  final String? imageUrl;
  final File? imageFile;
  final String? color;
  final String? material;
  final String? style;
  final String? season;
  final String? subCategory;
  final String? occasion;
  final String? fit;
  final String? pattern;
  final String? brand;
  final String? size;
  final String? careInstructions;
  final String? purchaseDate;
  final String? price;
  final String? notes;
  final String? mainGroup;

  ClothingItem({
    this.id,
    required this.category,
    required this.description,
    this.imageUrl,
    this.imageFile,
    this.color,
    this.material,
    this.style,
    this.season,
    this.subCategory,
    this.occasion,
    this.fit,
    this.pattern,
    this.brand,
    this.size,
    this.careInstructions,
    this.purchaseDate,
    this.price,
    this.notes,
    this.mainGroup,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'color': color,
      'material': material,
      'style': style,
      'season': season,
      'sub_category': subCategory,
      'occasion': occasion,
      'fit': fit,
      'pattern': pattern,
      'brand': brand,
      'size': size,
      'care_instructions': careInstructions,
      'purchase_date': purchaseDate,
      'price': price,
      'notes': notes,
      'main_group': mainGroup,
    };
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      category: json['category'],
      description: json['description'],
      imageUrl: json['image_url'],
      color: json['color'],
      material: json['material'],
      style: json['style'],
      season: json['season'],
      subCategory: json['sub_category'],
      occasion: json['occasion'],
      fit: json['fit'],
      pattern: json['pattern'],
      brand: json['brand'],
      size: json['size'],
      careInstructions: json['care_instructions'],
      purchaseDate: json['purchase_date'],
      price: json['price'],
      notes: json['notes'],
      mainGroup: json['main_group'],
    );
  }
}
