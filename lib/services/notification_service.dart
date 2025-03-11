import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await saveUserToken(token);
      }
    }
  }

  Future<void> saveUserToken(String token) async {
    // TODO: Save user's FCM token
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toJson());
  }

  Future<void> scheduleEventReminder(String eventId, DateTime eventTime) async {
    final reminder = eventTime.subtract(const Duration(hours: 24));
    
    await _messaging.schedule(
      'event_reminder_$eventId',
      'Upcoming Event Tomorrow',
      'Don\'t forget about your event tomorrow!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Event Reminders',
          importance: Importance.high,
        ),
        iOS: IOSNotificationDetails(),
      ),
      scheduledDate: reminder,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> scheduleWeeklyDigest(String userId) async {
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('participants.$userId', isEqualTo: 'going')
        .where('dateTime', isGreaterThan: Timestamp.now())
        .get();

    final events = eventsSnapshot.docs.map((doc) => doc.data()).toList();
    // Create and send digest notification
  }
}
