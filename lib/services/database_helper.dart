import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/group_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'campus_vibe.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT,
        fullName TEXT,
        university TEXT,
        department TEXT,
        graduationYear INTEGER,
        isVerified INTEGER,
        profileImageUrl TEXT,
        bio TEXT,
        createdAt TEXT
      )
    ''');

    // Posts table
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        authorId TEXT,
        content TEXT,
        contentType TEXT,
        mediaUrls TEXT,
        tags TEXT,
        courseCode TEXT,
        department TEXT,
        likeCount INTEGER,
        commentCount INTEGER,
        createdAt TEXT,
        FOREIGN KEY (authorId) REFERENCES users (uid)
      )
    ''');

    // Post likes table
    await db.execute('''
      CREATE TABLE post_likes (
        postId TEXT,
        userId TEXT,
        createdAt TEXT,
        PRIMARY KEY (postId, userId),
        FOREIGN KEY (postId) REFERENCES posts (id),
        FOREIGN KEY (userId) REFERENCES users (uid)
      )
    ''');

    // Comments table
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        postId TEXT,
        authorId TEXT,
        content TEXT,
        createdAt TEXT,
        FOREIGN KEY (postId) REFERENCES posts (id),
        FOREIGN KEY (authorId) REFERENCES users (uid)
      )
    ''');

    // Groups table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        university TEXT,
        department TEXT,
        imageUrl TEXT,
        creatorId TEXT,
        isPrivate INTEGER,
        createdAt TEXT,
        FOREIGN KEY (creatorId) REFERENCES users (uid)
      )
    ''');

    // Group members table
    await db.execute('''
      CREATE TABLE group_members (
        groupId TEXT,
        userId TEXT,
        role TEXT,
        joinedAt TEXT,
        PRIMARY KEY (groupId, userId),
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (userId) REFERENCES users (uid)
      )
    ''');
  }

  // User methods
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
  }

  Future<int> deleteUser(String uid) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // Post methods
  Future<int> insertPost(PostModel post) async {
    Database db = await database;
    return await db.insert('posts', post.toMap());
  }

  Future<PostModel?> getPost(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PostModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PostModel>> getAllPosts({
    bool? showAcademic,
    bool? showSocial,
    String? universityFilter,
    List<String>? tagFilters,
    String? departmentFilter,
  }) async {
    Database db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Build filter conditions
    List<String> conditions = [];

    if (showAcademic == true && showSocial == false) {
      conditions.add('contentType = ?');
      whereArgs.add('academic');
    } else if (showAcademic == false && showSocial == true) {
      conditions.add('contentType = ?');
      whereArgs.add('social');
    }

    if (universityFilter != null) {
      // We need to join with users table to filter by university
      // This will be handled in the query below
    }

    if (departmentFilter != null) {
      conditions.add('department = ?');
      whereArgs.add(departmentFilter);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    // Build the query
    String query = '''
      SELECT p.* FROM posts p
      INNER JOIN users u ON p.authorId = u.uid
    ''';

    if (whereClause.isNotEmpty || universityFilter != null) {
      query += ' WHERE ';
      
      if (whereClause.isNotEmpty) {
        query += whereClause;
      }
      
      if (universityFilter != null) {
        if (whereClause.isNotEmpty) {
          query += ' AND ';
        }
        query += 'u.university = ?';
        whereArgs.add(universityFilter);
      }
    }

    query += ' ORDER BY p.createdAt DESC';

    List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    
    // Filter by tags (done in memory since SQLite doesn't handle array contains well)
    List<PostModel> posts = maps.map((map) => PostModel.fromMap(map)).toList();
    
    if (tagFilters != null && tagFilters.isNotEmpty) {
      posts = posts.where((post) {
        for (var tag in tagFilters) {
          if (post.tags.contains(tag)) {
            return true;
          }
        }
        return false;
      }).toList();
    }
    
    return posts;
  }

  Future<List<PostModel>> searchPosts(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'posts',
      where: 'content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    
    return maps.map((map) => PostModel.fromMap(map)).toList();
  }

  Future<int> updatePost(PostModel post) async {
    Database db = await database;
    return await db.update(
      'posts',
      post.toMap(),
      where: 'id = ?',
      whereArgs: [post.id],
    );
  }

  Future<int> deletePost(String id) async {
    Database db = await database;
    
    // Delete associated likes and comments first
    await db.delete(
      'post_likes',
      where: 'postId = ?',
      whereArgs: [id],
    );
    
    await db.delete(
      'comments',
      where: 'postId = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Like methods
  Future<int> likePost(String postId, String userId) async {
    Database db = await database;
    
    // Check if already liked
    List<Map<String, dynamic>> existing = await db.query(
      'post_likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
    
    if (existing.isNotEmpty) {
      return 0; // Already liked
    }
    
    // Update post like count
    await db.rawUpdate(
      'UPDATE posts SET likeCount = likeCount + 1 WHERE id = ?',
      [postId],
    );
    
    // Insert like record
    return await db.insert('post_likes', {
      'postId': postId,
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> unlikePost(String postId, String userId) async {
    Database db = await database;
    
    // Check if liked
    List<Map<String, dynamic>> existing = await db.query(
      'post_likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
    
    if (existing.isEmpty) {
      return 0; // Not liked
    }
    
    // Update post like count
    await db.rawUpdate(
      'UPDATE posts SET likeCount = MAX(0, likeCount - 1) WHERE id = ?',
      [postId],
    );
    
    // Delete like record
    return await db.delete(
      'post_likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
  }

  Future<bool> isPostLikedByUser(String postId, String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'post_likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> getLikedUserIds(String postId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'post_likes',
      columns: ['userId'],
      where: 'postId = ?',
      whereArgs: [postId],
    );
    
    return maps.map((map) => map['userId'] as String).toList();
  }

  // Group methods
  Future<int> insertGroup(GroupModel group) async {
    Database db = await database;
    int result = await db.insert('groups', group.toMap());
    
    // Add creator as a member with admin role
    if (result > 0) {
      await db.insert('group_members', {
        'groupId': group.id,
        'userId': group.creatorId,
        'role': 'admin',
        'joinedAt': DateTime.now().toIso8601String(),
      });
    }
    
    return result;
  }

  Future<GroupModel?> getGroup(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return GroupModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<GroupModel>> getAllGroups({
    String? universityFilter,
    String? departmentFilter,
  }) async {
    Database db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Build filter conditions
    List<String> conditions = [];

    if (universityFilter != null) {
      conditions.add('university = ?');
      whereArgs.add(universityFilter);
    }

    if (departmentFilter != null) {
      conditions.add('department = ?');
      whereArgs.add(departmentFilter);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    List<Map<String, dynamic>> maps = await db.query(
      'groups',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereClause.isNotEmpty ? whereArgs : null,
      orderBy: 'createdAt DESC',
    );
    
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<List<GroupModel>> getUserGroups(String userId) async {
    Database db = await database;
    String query = '''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.groupId
      WHERE gm.userId = ?
      ORDER BY g.createdAt DESC
    ''';
    
    List<Map<String, dynamic>> maps = await db.rawQuery(query, [userId]);
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<int> updateGroup(GroupModel group) async {
    Database db = await database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(String id) async {
    Database db = await database;
    
    // Delete group members first
    await db.delete(
      'group_members',
      where: 'groupId = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Group membership methods
  Future<int> joinGroup(String groupId, String userId, {String role = 'member'}) async {
    Database db = await database;
    
    // Check if already a member
    List<Map<String, dynamic>> existing = await db.query(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
    
    if (existing.isNotEmpty) {
      return 0; // Already a member
    }
    
    return await db.insert('group_members', {
      'groupId': groupId,
      'userId': userId,
      'role': role,
      'joinedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> leaveGroup(String groupId, String userId) async {
    Database db = await database;
    return await db.delete(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<bool> isGroupMember(String groupId, String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
    return result.isNotEmpty;
  }

  Future<String?> getMemberRole(String groupId, String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'group_members',
      columns: ['role'],
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
    
    if (result.isNotEmpty) {
      return result.first['role'] as String;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    Database db = await database;
    String query = '''
      SELECT u.*, gm.role FROM users u
      INNER JOIN group_members gm ON u.uid = gm.userId
      WHERE gm.groupId = ?
      ORDER BY gm.role = 'admin' DESC, u.fullName ASC
    ''';
    
    return await db.rawQuery(query, [groupId]);
  }

  Future<int> updateMemberRole(String groupId, String userId, String newRole) async {
    Database db = await database;
    return await db.update(
      'group_members',
      {'role': newRole},
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
  }
}
