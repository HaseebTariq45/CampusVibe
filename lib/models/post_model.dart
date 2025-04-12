import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUniversity;
  final String authorProfileImage;
  final String content;
  final List<String> mediaUrls;
  final String contentType; // 'academic' or 'social'
  final List<String> tags;
  final int likes;
  final int comments;
  final int shares;
  final List<String> likedBy;
  final DateTime createdAt;
  final bool isModerated;
  final String courseCode; // Optional, for academic content
  final String department; // Optional, for academic content

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUniversity,
    required this.authorProfileImage,
    required this.content,
    this.mediaUrls = const [],
    required this.contentType,
    this.tags = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.isModerated = false,
    this.courseCode = '',
    this.department = '',
  });

  // Create a post from a Firebase document
  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorUniversity: data['authorUniversity'] ?? '',
      authorProfileImage: data['authorProfileImage'] ?? '',
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      contentType: data['contentType'] ?? 'social',
      tags: List<String>.from(data['tags'] ?? []),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isModerated: data['isModerated'] ?? false,
      courseCode: data['courseCode'] ?? '',
      department: data['department'] ?? '',
    );
  }

  // Convert post to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorUniversity': authorUniversity,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'contentType': contentType,
      'tags': tags,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'isModerated': isModerated,
      'courseCode': courseCode,
      'department': department,
    };
  }

  // Create a copy of the post with updated fields
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorUniversity,
    String? authorProfileImage,
    String? content,
    List<String>? mediaUrls,
    String? contentType,
    List<String>? tags,
    int? likes,
    int? comments,
    int? shares,
    List<String>? likedBy,
    DateTime? createdAt,
    bool? isModerated,
    String? courseCode,
    String? department,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUniversity: authorUniversity ?? this.authorUniversity,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      isModerated: isModerated ?? this.isModerated,
      courseCode: courseCode ?? this.courseCode,
      department: department ?? this.department,
    );
  }
}
