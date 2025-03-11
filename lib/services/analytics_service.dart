import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ml_algo/ml_algo.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseFirestore _firestore;

  AnalyticsService(this._analytics, this._firestore);

  Future<void> trackScreenView(String screenName, String userId) async {
    await _analytics.logScreenView(screenName: screenName);
    await _firestore.collection('user_activity').add({
      'userId': userId,
      'screenName': screenName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> trackUserEngagement({
    required String userId,
    required String actionType,
    required String targetId,
    Map<String, dynamic>? extraData,
  }) async {
    await _firestore.collection('user_engagement').add({
      'userId': userId,
      'actionType': actionType,
      'targetId': targetId,
      'timestamp': FieldValue.serverTimestamp(),
      'data': extraData,
    });
  }

  Stream<Map<String, dynamic>> getUserAnalytics(String userId) {
    return _firestore
        .collection('user_engagement')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs.map((doc) => doc.data()).toList();
          return _processUserAnalytics(activities);
        });
  }

  Map<String, dynamic> _processUserAnalytics(List<Map<String, dynamic>> activities) {
    // Process activities to generate insights
    return {
      'totalActions': activities.length,
      'mostFrequentAction': _getMostFrequentAction(activities),
      'activityByHour': _getActivityByHour(activities),
    };
  }

  String _getMostFrequentAction(List<Map<String, dynamic>> activities) {
    // Calculate most frequent action
    return 'comment'; // Simplified example
  }

  Map<int, int> _getActivityByHour(List<Map<String, dynamic>> activities) {
    // Calculate activity distribution by hour
    return {}; // Simplified example
  }

  Future<Map<String, dynamic>> getPredictedEngagement(String userId) async {
    final userActivity = await _getUserActivityData(userId);
    final predictions = await _runEngagementPredictions(userActivity);
    
    return {
      'bestTimeToPost': predictions['optimal_time'],
      'recommendedTopics': predictions['trending_topics'],
      'engagementScore': predictions['user_score'],
    };
  }

  Future<List<String>> _getTopPerformingTags() async {
    final snapshot = await _firestore
        .collection('post_analytics')
        .orderBy('engagementRate', descending: true)
        .limit(100)
        .get();

    final tags = <String, double>{};
    for (var doc in snapshot.docs) {
      final postTags = List<String>.from(doc['tags'] ?? []);
      for (var tag in postTags) {
        tags[tag] = (tags[tag] ?? 0) + doc['engagementRate'];
      }
    }

    return tags.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(10)
        .map((e) => e.key)
        .toList();
  }
}
