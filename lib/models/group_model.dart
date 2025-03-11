import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'course', 'faculty', 'interest'
  final String creatorId;
  final List<String> members;
  final List<String> moderators;
  final DateTime createdAt;
  final String university;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.creatorId,
    this.members = const [],
    this.moderators = const [],
    required this.createdAt,
    required this.university,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      creatorId: json['creatorId'],
      members: List<String>.from(json['members'] ?? []),
      moderators: List<String>.from(json['moderators'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      university: json['university'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'creatorId': creatorId,
    'members': members,
    'moderators': moderators,
    'createdAt': Timestamp.fromDate(createdAt),
    'university': university,
  };
}
