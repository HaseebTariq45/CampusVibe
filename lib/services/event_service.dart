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

  Future<void> createEventWithAnalytics(Map<String, dynamic> eventData) async {
    final batch = _firestore.batch();
    final eventRef = _firestore.collection('events').doc();
    final analyticsRef = _firestore.collection('event_analytics').doc(eventRef.id);

    batch.set(eventRef, {
      ...eventData,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [],
      'status': 'upcoming',
    });

    batch.set(analyticsRef, {
      'viewCount': 0,
      'interestedCount': 0,
      'rsvpStats': {
        'going': 0,
        'maybe': 0,
        'declined': 0,
      },
      'engagementRate': 0.0,
      'demographics': {},
    });

    await batch.commit();
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

  Future<void> updateRSVPStatus(String eventId, String userId, String status) async {
    final batch = _firestore.batch();
    final eventRef = _firestore.collection('events').doc(eventId);
    final analyticsRef = _firestore.collection('event_analytics').doc(eventId);

    // Update RSVP status
    batch.update(eventRef, {
      'participants.$userId': status,
    });

    // Update analytics
    batch.update(analyticsRef, {
      'rsvpStats.$status': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Create notification
    batch.set(_firestore.collection('notifications').doc(), {
      'type': 'event_rsvp',
      'eventId': eventId,
      'userId': userId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<Map<String, dynamic>> getEventAnalytics(String eventId) {
    return _firestore
        .collection('event_analytics')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }
}
