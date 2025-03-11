import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:device_info/device_info.dart';
import 'dart:io';
import 'package:ml_dataframe/ml_dataframe.dart';

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

  Future<Map<String, dynamic>> getEventInsights(String eventId) async {
    final analytics = await _firestore
        .collection('event_analytics')
        .doc(eventId)
        .get();
    
    final participantStats = await _calculateParticipantDemographics(eventId);
    final engagementScore = await _calculateEventEngagementScore(eventId);

    return {
      'basicStats': analytics.data(),
      'demographics': participantStats,
      'engagementScore': engagementScore,
      'predictions': await _predictEventSuccess(analytics.data()),
    };
  }

  Future<double> _calculateEventEngagementScore(String eventId) async {
    final event = await _firestore.collection('events').doc(eventId).get();
    final analytics = await _firestore.collection('event_analytics').doc(eventId).get();

    // Calculate engagement score based on views, RSVPs, and interaction rates
    return 0.0; // Simplified example
  }

  Future<void> logError(
    String errorMessage,
    StackTrace stackTrace,
    String userId,
    {Map<String, dynamic>? extraData}
  ) async {
    await _firestore.collection('error_logs').add({
      'error': errorMessage,
      'stackTrace': stackTrace.toString(),
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'deviceInfo': await _getDeviceInfo(),
      'extraData': extraData,
    });
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'deviceModel': deviceInfo.toString(),
    };
  }

  Future<Map<String, dynamic>> getUserInsights(String userId) async {
    final activities = await _firestore
        .collection('user_activity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();

    final data = activities.docs.map((doc) => doc.data()).toList();
    final dataFrame = DataFrame(data);
    
    return {
      'activityTrends': _calculateActivityTrends(dataFrame),
      'peakEngagementTimes': _findPeakEngagementTimes(dataFrame),
      'interestClusters': await _generateInterestClusters(dataFrame),
      'recommendedConnections': await _findRecommendedConnections(userId, dataFrame),
    };
  }

  Map<String, double> _calculateActivityTrends(DataFrame data) {
    // Implement ML-based trend analysis
    return {};
  }
}
