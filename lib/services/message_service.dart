import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    return _firestore
        .collection('messages')
        .where('participants', arrayContainsAny: [userId, otherUserId])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> sendMessage(MessageModel message) async {
    await _firestore.collection('messages').add(message.toJson());
  }

  Future<void> markAsRead(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'isRead': true,
    });
  }

  Future<String> uploadMessageFile(String chatId, File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_files')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}');
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> sendFileMessage(String senderId, String receiverId, File file) async {
    final url = await uploadMessageFile('$senderId_$receiverId', file);
    final message = MessageModel(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: url,
      timestamp: DateTime.now(),
      type: 'file',
    );
    await sendMessage(message);
  }

  Stream<Map<String, dynamic>> getChatStatus(String chatId) {
    return _firestore
        .collection('chat_status')
        .doc(chatId)
        .snapshots()
        .map((doc) => {
              'typing': List<String>.from(doc.data()?['typing'] ?? []),
              'online': List<String>.from(doc.data()?['online'] ?? []),
              'lastSeen': doc.data()?['lastSeen'] ?? {},
            });
  }

  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    final ref = _firestore.collection('chat_status').doc(chatId);
    
    if (isTyping) {
      await ref.update({
        'typing': FieldValue.arrayUnion([userId])
      });
    } else {
      await ref.update({
        'typing': FieldValue.arrayRemove([userId])
      });
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
