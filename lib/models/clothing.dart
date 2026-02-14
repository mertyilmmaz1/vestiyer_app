class Clothing {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String imageUrl;
  final String imagePath;
  final String? segmentedImageUrl;
  final List<String> colors; // Backend'den gelen renk array'i
  final AdvancedAnalysis? advancedAnalysis;
  final FormattedAnalysis? formattedAnalysis;
  final ApiUsage? apiUsage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Clothing({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.imagePath,
    this.segmentedImageUrl,
    required this.colors,
    this.advancedAnalysis,
    this.formattedAnalysis,
    this.apiUsage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Prefer segmented (background-removed) image when available.
  String get displayImageUrl => segmentedImageUrl ?? imageUrl;

  static List<String> _safeStringList(dynamic v) {
    if (v == null || v is! List) return [];
    return v.map((e) => e?.toString() ?? '').toList();
  }

  factory Clothing.fromJson(Map<String, dynamic> json) => Clothing(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] ?? '',
        title: json['title'],
        category: json['category'],
        imageUrl: json['imageUrl'],
        imagePath: json['imagePath'],
        segmentedImageUrl: json['segmentedImageUrl'],
        colors: _safeStringList(json['colors']),
        advancedAnalysis: json['advancedAnalysis'] != null
            ? AdvancedAnalysis.fromJson(json['advancedAnalysis'])
            : null,
        formattedAnalysis: json['formattedAnalysis'] != null
            ? FormattedAnalysis.fromJson(json['formattedAnalysis'])
            : null,
        apiUsage: json['apiUsage'] != null
            ? ApiUsage.fromJson(json['apiUsage'])
            : null,
        createdAt: _dateFromJson(json['createdAt']),
        updatedAt: _dateFromJson(json['updatedAt']),
      );

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  /// Firestore: use document id as id; map uses string dates for compatibility.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'category': category,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        if (segmentedImageUrl != null) 'segmentedImageUrl': segmentedImageUrl,
        'colors': colors,
        'advancedAnalysis': advancedAnalysis?.toJson(),
        'formattedAnalysis': formattedAnalysis?.toJson(),
        'apiUsage': apiUsage?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'title': title,
        'category': category,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        if (segmentedImageUrl != null) 'segmentedImageUrl': segmentedImageUrl,
        'colors': colors, // Renk array'i
        'advancedAnalysis': advancedAnalysis?.toJson(),
        'formattedAnalysis': formattedAnalysis?.toJson(),
        'apiUsage': apiUsage?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class AdvancedAnalysis {
  final String? mainGroup;
  final String? category;
  final String? color;
  final String? material;
  final String? style;
  final String? season;
  final String? details;
  final String? rawAnalysis;

  AdvancedAnalysis({
    this.mainGroup,
    this.category,
    this.color,
    this.material,
    this.style,
    this.season,
    this.details,
    this.rawAnalysis,
  });

  factory AdvancedAnalysis.fromJson(Map<String, dynamic> json) =>
      AdvancedAnalysis(
        mainGroup: json['mainGroup'],
        category: json['category'],
        color: json['color'],
        material: json['material'],
        style: json['style'],
        season: json['season'],
        details: json['details'],
        rawAnalysis: json['rawAnalysis'],
      );

  Map<String, dynamic> toJson() => {
        'mainGroup': mainGroup,
        'category': category,
        'color': color,
        'material': material,
        'style': style,
        'season': season,
        'details': details,
        'rawAnalysis': rawAnalysis,
      };
}

class FormattedAnalysis {
  final String? anaGrup;
  final String? kategori;
  final String? renk;
  final String? materyal;
  final String? stil;
  final String? sezon;
  final String? detaylar;

  FormattedAnalysis({
    this.anaGrup,
    this.kategori,
    this.renk,
    this.materyal,
    this.stil,
    this.sezon,
    this.detaylar,
  });

  factory FormattedAnalysis.fromJson(Map<String, dynamic> json) =>
      FormattedAnalysis(
        anaGrup: json['ana_grup'],
        kategori: json['kategori'],
        renk: json['renk'],
        materyal: json['materyal'],
        stil: json['stil'],
        sezon: json['sezon'],
        detaylar: json['detaylar'],
      );

  Map<String, dynamic> toJson() => {
        'ana_grup': anaGrup,
        'kategori': kategori,
        'renk': renk,
        'materyal': materyal,
        'stil': stil,
        'sezon': sezon,
        'detaylar': detaylar,
      };
}

class ApiUsage {
  final int promptTokens;
  final int completionTokens;
  final double totalCost;
  final String model;
  final DateTime analyzedAt;

  ApiUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalCost,
    required this.model,
    required this.analyzedAt,
  });

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  static int _safeInt(dynamic v) => (v is int) ? v : (v is num) ? v.toInt() : 0;

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory ApiUsage.fromJson(Map<String, dynamic> json) => ApiUsage(
        promptTokens: _safeInt(json['promptTokens']),
        completionTokens: _safeInt(json['completionTokens']),
        totalCost: _safeDouble(json['totalCost']),
        model: json['model']?.toString() ?? '',
        analyzedAt: _dateFromJson(json['analyzedAt']),
      );

  Map<String, dynamic> toJson() => {
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalCost': totalCost,
        'model': model,
        'analyzedAt': analyzedAt.toIso8601String(),
      };
}
