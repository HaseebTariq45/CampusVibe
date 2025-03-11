class UserModel {
  final String uid;
  final String email;
  final String name;
  final String university;
  final String department;
  final int year;
  final String profileImage;
  final List<String> interests;
  final int points;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.university,
    required this.department,
    required this.year,
    this.profileImage = '',
    this.interests = const [],
    this.points = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      university: json['university'] as String,
      department: json['department'] as String,
      year: json['year'] as int,
      profileImage: json['profileImage'] as String? ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'university': university,
    'department': department,
    'year': year,
    'profileImage': profileImage,
    'interests': interests,
    'points': points,
  };
}
