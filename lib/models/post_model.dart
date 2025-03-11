import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final String type; // 'academic' or 'social'
  final List<String> tags;
  final List<String> likes;
  final List<String> attachments;
  final DateTime createdAt;
  final int reportCount;

  PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.type,
    this.tags = const [],
    this.likes = const [],
    this.attachments = const [],
    required this.createdAt,
    this.reportCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      authorId: json['authorId'],
      content: json['content'],
      type: json['type'],
      tags: List<String>.from(json['tags'] ?? []),
      likes: List<String>.from(json['likes'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      reportCount: json['reportCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'content': content,
    'type': type,
    'tags': tags,
    'likes': likes,
    'attachments': attachments,
    'createdAt': Timestamp.fromDate(createdAt),
    'reportCount': reportCount,
  };
}
