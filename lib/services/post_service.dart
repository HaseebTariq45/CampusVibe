import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new post
  Future<String> createPost({
    required String authorId,
    required String content,
    required String contentType,
    required List<String> tags,
    List<File>? mediaFiles,
    String courseCode = '',
    String department = '',
    required UserModel author,
  }) async {
    try {
      // Upload media files if any
      List<String> mediaUrls = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        mediaUrls = await _uploadMediaFiles(authorId, mediaFiles);
      }

      // Create post document
      DocumentReference postRef = await _firestore.collection('posts').add({
        'authorId': authorId,
        'authorName': author.fullName,
        'authorUniversity': author.university,
        'authorProfileImage': author.profileImageUrl,
        'content': content,
        'mediaUrls': mediaUrls,
        'contentType': contentType,
        'tags': tags,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': [],
        'createdAt': DateTime.now(),
        'isModerated': false,
        'courseCode': courseCode,
        'department': department,
      });

      return postRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Upload media files to Firebase Storage
  Future<List<String>> _uploadMediaFiles(
      String authorId, List<File> mediaFiles) async {
    List<String> mediaUrls = [];

    for (var file in mediaFiles) {
      String fileName =
          'posts/$authorId/${DateTime.now().millisecondsSinceEpoch}_${mediaFiles.indexOf(file)}';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      mediaUrls.add(downloadUrl);
    }

    return mediaUrls;
  }

  // Get posts for feed (with filtering options)
  Stream<List<PostModel>> getPostsForFeed({
    bool showAcademic = true,
    bool showSocial = true,
    String? universityFilter,
    List<String>? tagFilters,
    String? departmentFilter,
    int limit = 20,
  }) {
    Query query = _firestore.collection('posts').orderBy('createdAt', descending: true);

    // Apply content type filter
    if (showAcademic && !showSocial) {
      query = query.where('contentType', isEqualTo: 'academic');
    } else if (!showAcademic && showSocial) {
      query = query.where('contentType', isEqualTo: 'social');
    }

    // Apply university filter
    if (universityFilter != null && universityFilter.isNotEmpty) {
      query = query.where('authorUniversity', isEqualTo: universityFilter);
    }

    // Apply department filter
    if (departmentFilter != null && departmentFilter.isNotEmpty) {
      query = query.where('department', isEqualTo: departmentFilter);
    }

    // Apply tag filter (this is a simplified approach, for exact tag matching)
    // For more complex tag filtering, you might need to use a different approach
    if (tagFilters != null && tagFilters.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tagFilters);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get posts for a specific user
  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get posts for a specific group
  Stream<List<PostModel>> getGroupPosts(String groupId, {int limit = 20}) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      // Get the post document
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      DocumentSnapshot postDoc = await postRef.get();
      
      if (postDoc.exists) {
        Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
        List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
        
        // Check if user already liked the post
        if (!likedBy.contains(userId)) {
          likedBy.add(userId);
          await postRef.update({
            'likes': FieldValue.increment(1),
            'likedBy': likedBy,
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      // Get the post document
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      DocumentSnapshot postDoc = await postRef.get();
      
      if (postDoc.exists) {
        Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
        List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
        
        // Check if user already liked the post
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          await postRef.update({
            'likes': FieldValue.increment(-1),
            'likedBy': likedBy,
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Search posts by content or tags
  Future<List<PostModel>> searchPosts(String query, {int limit = 20}) async {
    try {
      // This is a simple implementation that searches for posts containing the query in content
      // For a more sophisticated search, you might want to use a service like Algolia or implement
      // a more complex search algorithm
      
      // Search in content
      QuerySnapshot contentResults = await _firestore
          .collection('posts')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();
      
      // Search in tags (exact match)
      QuerySnapshot tagResults = await _firestore
          .collection('posts')
          .where('tags', arrayContains: query)
          .limit(limit)
          .get();
      
      // Combine results and remove duplicates
      Set<String> uniqueIds = {};
      List<PostModel> posts = [];
      
      for (var doc in contentResults.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          posts.add(PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
      for (var doc in tagResults.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          posts.add(PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
      // Sort by creation date (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return posts;
    } catch (e) {
      rethrow;
    }
  }
}
