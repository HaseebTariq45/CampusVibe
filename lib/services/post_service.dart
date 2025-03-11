import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService;
  final _postsSubject = BehaviorSubject<List<PostModel>>();

  Stream<List<PostModel>> getFeedPosts({String? university, List<String>? interests}) {
    Query query = _firestore.collection('posts');

    if (university != null) {
      query = query.where('university', isEqualTo: university);
    }
    if (interests != null && interests.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: interests);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
          final posts = snapshot.docs.map((doc) => 
            PostModel.fromJson({...doc.data(), 'id': doc.id})).toList();
          
          // Load author details
          for (var post in posts) {
            final authorDoc = await _firestore.collection('users').doc(post.authorId).get();
            post.authorDetails = UserModel.fromJson(authorDoc.data()!);
          }
          
          return posts;
        });
  }

  List<PostModel> _getCachedPosts() {
    final cached = _cacheService.getCachedData<List<dynamic>>(
      'feed_posts',
      (json) => (json['posts'] as List)
          .map((post) => PostModel.fromJson(post))
          .toList(),
    );
    return cached ?? [];
  }

  Stream<List<PostModel>> getFilteredPosts(String type) {
    return _firestore
        .collection('posts')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> createPost(PostModel post) async {
    final batch = _firestore.batch();
    final postRef = _firestore.collection('posts').doc();
    
    batch.set(postRef, post.toJson());
    batch.set(_firestore.collection('analytics').doc(), {
      'type': 'post_created',
      'userId': post.authorId,
      'postType': post.type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (post.type == 'academic') {
      batch.update(
        _firestore.collection('users').doc(post.authorId),
        {'points': FieldValue.increment(5)},
      );
    }

    await batch.commit();
    FirebaseAnalytics.instance.logEvent(name: 'post_created', parameters: {
      'post_type': post.type,
      'has_attachments': post.attachments.isNotEmpty,
    });
  }

  Future<void> createPostWithAnalytics(PostModel post) async {
    final batch = _firestore.batch();
    final postRef = _firestore.collection('posts').doc();
    final analyticsRef = _firestore.collection('post_analytics').doc(postRef.id);
    
    batch.set(postRef, post.toJson());
    batch.set(analyticsRef, {
      'views': 0,
      'uniqueViewers': [],
      'shareCount': 0,
      'engagementRate': 0.0,
      'timeSpentMs': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> trackPostEngagement(String postId, String userId, int timeSpentMs) async {
    final analyticsRef = _firestore.collection('post_analytics').doc(postId);
    
    await analyticsRef.update({
      'uniqueViewers': FieldValue.arrayUnion([userId]),
      'timeSpentMs': FieldValue.increment(timeSpentMs),
      'engagementRate': FieldValue.increment(0.1),
    });
  }

  Stream<List<PostModel>> getTrendingPosts() {
    return _firestore
        .collection('posts')
        .orderBy('likeCount', descending: true)
        .orderBy('commentCount', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
          final posts = snapshot.docs
              .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Load analytics data
          for (var post in posts) {
            final analytics = await _firestore
                .collection('post_analytics')
                .doc(post.id)
                .get();
            post.analytics = analytics.data();
          }
          
          return posts;
        });
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId])
    });
  }

  Future<void> reportPost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'reportCount': FieldValue.increment(1)
    });
  }

  Future<void> addComment(CommentModel comment) async {
    await _firestore.collection('comments').add(comment.toJson());
    
    // Update post's comment count
    await _firestore.collection('posts').doc(comment.postId).update({
      'commentCount': FieldValue.increment(1)
    });
  }

  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> likeComment(String commentId, String userId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> toggleLike(String postId) async {
    final batch = _firestore.batch();
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      final likes = List<String>.from(post.data()?['likes'] ?? []);

      if (likes.contains(userId)) {
        batch.update(postRef, {
          'likes': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        batch.update(postRef, {
          'likes': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });

        // Create notification for post author
        if (post.data()?['authorId'] != userId) {
          final notification = {
            'type': 'like',
            'userId': post.data()?['authorId'],
            'triggeredBy': userId,
            'postId': postId,
            'timestamp': FieldValue.serverTimestamp(),
          };
          batch.set(_firestore.collection('notifications').doc(), notification);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Stream<List<PostModel>> getUniversityPosts(String university) {
    return _firestore
        .collection('posts')
        .where('university', isEqualTo: university)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .handleError((error) {
          print('Error fetching university posts: $error');
          return Stream.value([]);
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<List<PostModel>> getRecommendedPosts(String userId) async {
    final trace = FirebasePerformance.instance.newTrace('recommended_posts');
    await trace.start();
    
    try {
      final userInterests = await _getUserInterests(userId);
      final recentInteractions = await _getRecentInteractions(userId);
      
      // Complex query combining user interests and interaction patterns
      final recommendedPosts = await _firestore
          .collection('posts')
          .where('tags', arrayContainsAny: userInterests)
          .orderBy('score', descending: true)
          .limit(10)
          .get();
      
      return recommendedPosts.docs
          .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } finally {
      await trace.stop();
    }
  }

  Future<double> _calculatePostScore(DocumentSnapshot post) async {
    const weights = {
      'likes': 1.0,
      'comments': 2.0,
      'shares': 3.0,
      'timeDecay': 0.1,
    };

    final data = post.data() as Map<String, dynamic>;
    final age = DateTime.now().difference(data['createdAt'].toDate()).inHours;
    
    return (data['likeCount'] * weights['likes']! +
            data['commentCount'] * weights['comments']! +
            data['shareCount'] * weights['shares']!) *
        exp(-weights['timeDecay']! * age);
  }
}
