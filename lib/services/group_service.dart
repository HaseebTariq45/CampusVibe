import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new group
  Future<String> createGroup({
    required String name,
    required String description,
    required String university,
    required String groupType,
    required String creatorId,
    File? imageFile,
    bool isPrivate = false,
    String courseCode = '',
    String department = '',
    List<String> tags = const [],
  }) async {
    try {
      // Upload group image if provided
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadGroupImage(creatorId, imageFile);
      }

      // Create group document
      DocumentReference groupRef = await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'university': university,
        'groupType': groupType,
        'creatorId': creatorId,
        'moderatorIds': [creatorId],
        'memberIds': [creatorId],
        'imageUrl': imageUrl,
        'isPrivate': isPrivate,
        'courseCode': courseCode,
        'department': department,
        'tags': tags,
        'createdAt': DateTime.now(),
        'lastActive': DateTime.now(),
      });

      // Add group to user's groups
      await _firestore.collection('users').doc(creatorId).update({
        'followingGroups': FieldValue.arrayUnion([groupRef.id]),
      });

      return groupRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Upload group image to Firebase Storage
  Future<String> _uploadGroupImage(String creatorId, File imageFile) async {
    String fileName =
        'groups/$creatorId/${DateTime.now().millisecondsSinceEpoch}';
    Reference storageRef = _storage.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Get group details
  Future<GroupModel?> getGroupDetails(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('groups').doc(groupId).get();
      
      if (doc.exists) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get groups by university
  Stream<List<GroupModel>> getGroupsByUniversity(String university, {int limit = 20}) {
    return _firestore
        .collection('groups')
        .where('university', isEqualTo: university)
        .orderBy('lastActive', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get groups by type
  Stream<List<GroupModel>> getGroupsByType(String groupType, {int limit = 20}) {
    return _firestore
        .collection('groups')
        .where('groupType', isEqualTo: groupType)
        .orderBy('lastActive', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get user's groups
  Stream<List<GroupModel>> getUserGroups(String userId, {int limit = 20}) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('lastActive', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Join a group
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      // Add user to group members
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Add group to user's groups
      await _firestore.collection('users').doc(userId).update({
        'followingGroups': FieldValue.arrayUnion([groupId]),
      });

      // Update group's last active timestamp
      await _firestore.collection('groups').doc(groupId).update({
        'lastActive': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      // Get group details
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        
        // Check if user is the creator
        if (data['creatorId'] == userId) {
          throw Exception('Group creator cannot leave the group. Delete the group instead.');
        }
        
        // Remove user from group members
        await _firestore.collection('groups').doc(groupId).update({
          'memberIds': FieldValue.arrayRemove([userId]),
          'moderatorIds': FieldValue.arrayRemove([userId]), // Also remove from moderators if applicable
        });

        // Remove group from user's groups
        await _firestore.collection('users').doc(userId).update({
          'followingGroups': FieldValue.arrayRemove([groupId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add moderator to group
  Future<void> addModerator(String groupId, String userId, String currentUserId) async {
    try {
      // Check if current user is creator or moderator
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        List<String> moderatorIds = List<String>.from(data['moderatorIds'] ?? []);
        
        if (data['creatorId'] != currentUserId && !moderatorIds.contains(currentUserId)) {
          throw Exception('Only group creator or moderators can add new moderators.');
        }
        
        // Add user to moderators
        await _firestore.collection('groups').doc(groupId).update({
          'moderatorIds': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Remove moderator from group
  Future<void> removeModerator(String groupId, String userId, String currentUserId) async {
    try {
      // Check if current user is creator
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        
        if (data['creatorId'] != currentUserId) {
          throw Exception('Only group creator can remove moderators.');
        }
        
        // Remove user from moderators
        await _firestore.collection('groups').doc(groupId).update({
          'moderatorIds': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId, String currentUserId) async {
    try {
      // Check if current user is creator
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        
        if (data['creatorId'] != currentUserId) {
          throw Exception('Only group creator can delete the group.');
        }
        
        // Get all members
        List<String> memberIds = List<String>.from(data['memberIds'] ?? []);
        
        // Remove group from all members' followingGroups
        for (String memberId in memberIds) {
          await _firestore.collection('users').doc(memberId).update({
            'followingGroups': FieldValue.arrayRemove([groupId]),
          });
        }
        
        // Delete group document
        await _firestore.collection('groups').doc(groupId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Search groups by name, description, or tags
  Future<List<GroupModel>> searchGroups(String query, {int limit = 20}) async {
    try {
      // Search in name
      QuerySnapshot nameResults = await _firestore
          .collection('groups')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();
      
      // Search in description
      QuerySnapshot descResults = await _firestore
          .collection('groups')
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();
      
      // Search in tags (exact match)
      QuerySnapshot tagResults = await _firestore
          .collection('groups')
          .where('tags', arrayContains: query)
          .limit(limit)
          .get();
      
      // Combine results and remove duplicates
      Set<String> uniqueIds = {};
      List<GroupModel> groups = [];
      
      for (var doc in nameResults.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          groups.add(GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
      for (var doc in descResults.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          groups.add(GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
      for (var doc in tagResults.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          groups.add(GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      
      // Sort by last active (most recent first)
      groups.sort((a, b) => b.lastActive.compareTo(a.lastActive));
      
      return groups;
    } catch (e) {
      rethrow;
    }
  }
}
