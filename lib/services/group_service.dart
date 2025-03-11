import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<GroupModel> createGroup(GroupModel group) async {
    final docRef = await _firestore.collection('groups').add(group.toJson());
    return group.copyWith(id: docRef.id);
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId])
    });
  }
}
