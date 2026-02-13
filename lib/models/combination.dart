import 'clothing.dart';

class Combination {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String occasion;
  final String season;
  final List<CombinationItem> clothingItems;
  final bool isAIGenerated;
  final bool isFavorite;
  final int? rating;
  final int timesWorn;
  final DateTime? lastWorn;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Combination({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.occasion,
    required this.season,
    required this.clothingItems,
    required this.isAIGenerated,
    required this.isFavorite,
    this.rating,
    required this.timesWorn,
    this.lastWorn,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Combination.fromJson(Map<String, dynamic> json) => Combination(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] ?? '',
        name: json['name'],
        description: json['description'],
        occasion: json['occasion'],
        season: json['season'],
        clothingItems: (json['clothingItems'] as List<dynamic>?)
                ?.map((item) => CombinationItem.fromJson(Map<String, dynamic>.from(item as Map)))
                .toList() ??
            [],
        isAIGenerated: json['isAIGenerated'] ?? false,
        isFavorite: json['isFavorite'] ?? false,
        rating: json['rating'],
        timesWorn: json['timesWorn'] ?? 0,
        lastWorn: json['lastWorn'] != null ? Combination._dateFromJson(json['lastWorn']) : null,
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: Combination._dateFromJson(json['createdAt']),
        updatedAt: Combination._dateFromJson(json['updatedAt']),
      );

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'occasion': occasion,
        'season': season,
        'clothingItems': clothingItems.map((e) => e.toJson()).toList(),
        'isAIGenerated': isAIGenerated,
        'isFavorite': isFavorite,
        'rating': rating,
        'timesWorn': timesWorn,
        'lastWorn': lastWorn,
        'tags': tags,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'occasion': occasion,
        'season': season,
        'clothingItems': clothingItems.map((item) => item.toJson()).toList(),
        'isAIGenerated': isAIGenerated,
        'isFavorite': isFavorite,
        'rating': rating,
        'timesWorn': timesWorn,
        'lastWorn': lastWorn?.toIso8601String(),
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CombinationItem {
  final String clothingId;
  final String? category;
  final bool isRequired;
  final Clothing? clothingDetails;

  CombinationItem({
    required this.clothingId,
    this.category,
    required this.isRequired,
    this.clothingDetails,
  });

  factory CombinationItem.fromJson(Map<String, dynamic> json) =>
      CombinationItem(
        clothingId: json['clothingId'] is String
            ? json['clothingId']
            : json['clothingId']['_id'],
        category: json['category'],
        isRequired: json['isRequired'] ?? true,
        clothingDetails: json['clothingId'] is Map<String, dynamic>
            ? Clothing.fromJson(json['clothingId'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'clothingId': clothingId,
        'category': category,
        'isRequired': isRequired,
      };
}
