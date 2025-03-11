import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String organizerId,
    required String university,
    required String type,
    String? venue,
    int? maxParticipants,
  }) async {
    await _firestore.collection('events').add({
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'organizerId': organizerId,
      'university': university,
      'type': type,
      'venue': venue,
      'maxParticipants': maxParticipants,
      'participants': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getUpcomingEvents(String university) {
    return _firestore
        .collection('events')
        .where('university', isEqualTo: university)
        .where('dateTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> joinEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }
}
