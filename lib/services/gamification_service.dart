import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> awardPoints(String userId, String action, int points) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final achievementRef = _firestore.collection('achievements').doc();

    batch.update(userRef, {
      'points': FieldValue.increment(points),
      'actionsCount.$action': FieldValue.increment(1),
    });

    batch.set(achievementRef, {
      'userId': userId,
      'action': action,
      'points': points,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getLeaderboard(String universityId) {
    return _firestore
        .collection('users')
        .where('university', isEqualTo: universityId)
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'userId': doc.id,
                  'name': doc['name'],
                  'points': doc['points'],
                  'department': doc['department'],
                })
            .toList());
  }

  Future<void> processAchievement(String userId, String action) async {
    final batch = _firestore.batch();
    final achievements = await _checkAchievements(userId, action);
    
    for (final achievement in achievements) {
      batch.set(_firestore.collection('user_achievements').doc(), {
        'userId': userId,
        'achievementId': achievement['id'],
        'timestamp': FieldValue.serverTimestamp(),
        'rewards': achievement['rewards'],
      });

      // Update user stats
      batch.update(_firestore.collection('users').doc(userId), {
        'points': FieldValue.increment(achievement['points']),
        'level': FieldValue.increment(achievement['levelUp'] ? 1 : 0),
        'achievements': FieldValue.arrayUnion([achievement['id']]),
      });
    }

    await batch.commit();
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final user = await _firestore.collection('users').doc(userId).get();
    final achievements = await _firestore
        .collection('user_achievements')
        .where('userId', isEqualTo: userId)
        .get();

    return {
      'level': user.data()?['level'] ?? 1,
      'points': user.data()?['points'] ?? 0,
      'achievements': achievements.docs.length,
      'ranking': await _calculateUserRanking(userId),
      'nextAchievements': await _getNextPossibleAchievements(userId),
    };
  }
}
