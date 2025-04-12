import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String university;
  final String groupType; // 'course', 'faculty', 'interest'
  final String creatorId;
  final List<String> moderatorIds;
  final List<String> memberIds;
  final String imageUrl;
  final bool isPrivate;
  final String courseCode; // Optional, for course-based groups
  final String department; // Optional, for faculty-based groups
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastActive;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.university,
    required this.groupType,
    required this.creatorId,
    this.moderatorIds = const [],
    this.memberIds = const [],
    this.imageUrl = '',
    this.isPrivate = false,
    this.courseCode = '',
    this.department = '',
    this.tags = const [],
    required this.createdAt,
    required this.lastActive,
  });

  // Create a group from a Firebase document
  factory GroupModel.fromMap(Map<String, dynamic> data, String id) {
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      university: data['university'] ?? '',
      groupType: data['groupType'] ?? 'interest',
      creatorId: data['creatorId'] ?? '',
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      courseCode: data['courseCode'] ?? '',
      department: data['department'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert group to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'university': university,
      'groupType': groupType,
      'creatorId': creatorId,
      'moderatorIds': moderatorIds,
      'memberIds': memberIds,
      'imageUrl': imageUrl,
      'isPrivate': isPrivate,
      'courseCode': courseCode,
      'department': department,
      'tags': tags,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  // Create a copy of the group with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? university,
    String? groupType,
    String? creatorId,
    List<String>? moderatorIds,
    List<String>? memberIds,
    String? imageUrl,
    bool? isPrivate,
    String? courseCode,
    String? department,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      university: university ?? this.university,
      groupType: groupType ?? this.groupType,
      creatorId: creatorId ?? this.creatorId,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberIds: memberIds ?? this.memberIds,
      imageUrl: imageUrl ?? this.imageUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      courseCode: courseCode ?? this.courseCode,
      department: department ?? this.department,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Get member count
  int get memberCount => memberIds.length;

  // Check if a user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  // Check if a user is a moderator
  bool isModerator(String userId) => moderatorIds.contains(userId) || creatorId == userId;
}
