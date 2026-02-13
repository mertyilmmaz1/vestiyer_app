class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
    required this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? json['id'] ?? '',
        email: json['email'] ?? '',
        firstName: json['firstName'],
        lastName: json['lastName'],
        profileImage: json['profileImage'],
        createdAt: User._dateFromJson(json['createdAt']),
        lastLogin: json['lastLogin'] != null
            ? User._dateFromJson(json['lastLogin'])
            : null,
        isActive: json['isActive'] ?? true,
        isPremium: json['isPremium'] ?? false,
      );

  static DateTime _dateFromJson(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return (v as dynamic).toDate();
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'profileImage': profileImage,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
        'isActive': isActive,
        'isPremium': isPremium,
      };

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'profileImage': profileImage,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
        'isActive': isActive,
        'isPremium': isPremium,
      };
}
