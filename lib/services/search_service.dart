import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/group_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<PostModel>> searchPosts(String query) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('tags', arrayContains: query)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<GroupModel>> searchGroups(String query, String university) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('university', isEqualTo: university)
        .where('name', isGreaterThanOrEqualTo: query)
        .get();

    return snapshot.docs
        .map((doc) => GroupModel.fromJson(doc.data()))
        .toList();
  }

  Future<Map<String, dynamic>> searchAll(String query, String university) async {
    final results = await Future.wait([
      searchUsers(query),
      searchPosts(query),
      searchGroups(query, university),
    ]);

    return {
      'users': results[0],
      'posts': results[1],
      'groups': results[2],
    };
  }

  Future<List<PostModel>> searchPostsByTopic(String topic, String type) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('type', isEqualTo: type)
        .where('tags', arrayContains: topic.toLowerCase())
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<UserModel>> searchUsersByInterest(String interest) async {
    final snapshot = await _firestore
        .collection('users')
        .where('interests', arrayContains: interest.toLowerCase())
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<PostModel>> searchPostsWithFilters(
    String query,
    String type,
    String university,
    {int limit = 20, DocumentSnapshot? lastDocument}
  ) async {
    Query query = _firestore
        .collection('posts')
        .where('type', isEqualTo: type)
        .where('university', isEqualTo: university)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<GroupModel>> searchGroupsWithFilters(
    String query,
    List<String> types,
    String university,
    {int limit = 20, DocumentSnapshot? lastDocument}
  ) async {
    Query query = _firestore
        .collection('groups')
        .where('type', whereIn: types)
        .where('university', isEqualTo: university)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
