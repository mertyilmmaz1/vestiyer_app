/// Single log entry: user wore a combination on [wornAt].
/// Snapshot fields (combinationName, occasion) allow display even if combination is later deleted.
class OutfitLog {
  final String id;
  final String userId;
  final String combinationId;
  final DateTime wornAt;
  final String? note;
  final String? combinationName;
  final String? occasion;

  OutfitLog({
    required this.id,
    required this.userId,
    required this.combinationId,
    required this.wornAt,
    this.note,
    this.combinationName,
    this.occasion,
  });

  factory OutfitLog.fromJson(Map<String, dynamic> json) => OutfitLog(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] ?? '',
        combinationId: json['combinationId'] ?? '',
        wornAt: OutfitLog._dateFromJson(json['wornAt']),
        note: json['note'] != null ? json['note'].toString() : null,
        combinationName: json['combinationName'] != null ? json['combinationName'].toString() : null,
        occasion: json['occasion'] != null ? json['occasion'].toString() : null,
      );

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  Map<String, dynamic> toFirestore() => {
        'combinationId': combinationId,
        'wornAt': wornAt,
        if (note != null) 'note': note,
        if (combinationName != null) 'combinationName': combinationName,
        if (occasion != null) 'occasion': occasion,
      };

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'combinationId': combinationId,
        'wornAt': wornAt.toIso8601String(),
        'note': note,
        'combinationName': combinationName,
        'occasion': occasion,
      };
}
