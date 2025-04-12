class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String university;
  final String department;
  final int graduationYear;
  final String profileImageUrl;
  final String verificationStatus;
  final List<String> interests;
  final List<String> followingUsers;
  final List<String> followingGroups;
  final int points;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.university,
    required this.department,
    required this.graduationYear,
    this.profileImageUrl = '',
    this.verificationStatus = 'pending',
    this.interests = const [],
    this.followingUsers = const [],
    this.followingGroups = const [],
    this.points = 0,
    this.preferences = const {
      'showAcademicContent': true,
      'showSocialContent': true,
      'notificationsEnabled': true,
    },
    required this.createdAt,
    required this.lastActive,
  });

  // Create a user from a Firebase document
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      university: data['university'] ?? '',
      department: data['department'] ?? '',
      graduationYear: data['graduationYear'] ?? DateTime.now().year,
      profileImageUrl: data['profileImageUrl'] ?? '',
      verificationStatus: data['verificationStatus'] ?? 'pending',
      interests: List<String>.from(data['interests'] ?? []),
      followingUsers: List<String>.from(data['followingUsers'] ?? []),
      followingGroups: List<String>.from(data['followingGroups'] ?? []),
      points: data['points'] ?? 0,
      preferences: data['preferences'] ?? {
        'showAcademicContent': true,
        'showSocialContent': true,
        'notificationsEnabled': true,
      },
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert user to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'university': university,
      'department': department,
      'graduationYear': graduationYear,
      'profileImageUrl': profileImageUrl,
      'verificationStatus': verificationStatus,
      'interests': interests,
      'followingUsers': followingUsers,
      'followingGroups': followingGroups,
      'points': points,
      'preferences': preferences,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? university,
    String? department,
    int? graduationYear,
    String? profileImageUrl,
    String? verificationStatus,
    List<String>? interests,
    List<String>? followingUsers,
    List<String>? followingGroups,
    int? points,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      department: department ?? this.department,
      graduationYear: graduationYear ?? this.graduationYear,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      interests: interests ?? this.interests,
      followingUsers: followingUsers ?? this.followingUsers,
      followingGroups: followingGroups ?? this.followingGroups,
      points: points ?? this.points,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
