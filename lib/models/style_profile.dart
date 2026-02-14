/// Kullanıcının Stil DNA profilini temsil eder.
/// Kayıt / onboarding sırasında toplanır, kombin motorunda kullanılır.
class StyleProfile {
  final List<String> styleDNA;
  final List<String> colorBias;
  final String fitPreference;
  final String lifestyle;
  final DateTime? completedAt;

  const StyleProfile({
    required this.styleDNA,
    required this.colorBias,
    required this.fitPreference,
    required this.lifestyle,
    this.completedAt,
  });

  factory StyleProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StyleProfile.empty;
    return StyleProfile(
      styleDNA: (json['styleDNA'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      colorBias: (json['colorBias'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fitPreference: json['fitPreference']?.toString() ?? 'regular',
      lifestyle: json['lifestyle']?.toString() ?? 'office',
      completedAt: json['completedAt'] != null
          ? _dateFromJson(json['completedAt'])
          : null,
    );
  }

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  Map<String, dynamic> toFirestore() => {
        'styleDNA': styleDNA,
        'colorBias': colorBias,
        'fitPreference': fitPreference,
        'lifestyle': lifestyle,
        if (completedAt != null) 'completedAt': completedAt,
      };

  /// JSON-safe map for jsonEncode (DateTime -> String).
  Map<String, dynamic> toJson() => {
        'styleDNA': styleDNA,
        'colorBias': colorBias,
        'fitPreference': fitPreference,
        'lifestyle': lifestyle,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  bool get isCompleted => completedAt != null && styleDNA.isNotEmpty;

  static const StyleProfile empty = StyleProfile(
    styleDNA: [],
    colorBias: [],
    fitPreference: 'regular',
    lifestyle: 'office',
  );
}
