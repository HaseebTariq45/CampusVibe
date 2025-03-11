import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> replies;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      content: json['content'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(json['likes'] ?? []),
      replies: List<String>.from(json['replies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'userId': userId,
    'content': content,
    'createdAt': Timestamp.fromDate(createdAt),
    'likes': likes,
    'replies': replies,
  };
}
