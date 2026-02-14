class ApiUsage {
  final String id;
  final String userId;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final double cost;
  final DateTime timestamp;

  ApiUsage({
    required this.id,
    required this.userId,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.cost,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'model': model,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'cost': cost,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  factory ApiUsage.fromMap(Map<String, dynamic> map) {
    return ApiUsage(
      id: map['id'],
      userId: map['user_id'],
      model: map['model'],
      promptTokens: map['prompt_tokens'],
      completionTokens: map['completion_tokens'],
      cost: map['cost'],
      timestamp: _dateFromJson(map['timestamp']),
    );
  }
}
