import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

  // Collection references
  static const String usersCollection = 'users';
  static const String embeddingsCollection = 'face_embeddings';

  /// Save user to Firestore (without embedding)
  Future<void> saveUser({
    required String userId,
    required String name,
    required String email,
    required String faceId,
    String? imagePath,
  }) async {
    try {
      final userRef = _firestore.collection(usersCollection).doc(userId);
      await userRef.set({
        'name': name,
        'email': email,
        'faceId': faceId,
        'imagePath': imagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('✅ User saved to Firestore');
    } catch (e) {
      log('❌ Error saving user to Firestore: $e');
      rethrow;
    }
  }

  /// Save user with face embedding to Firestore
  Future<void> saveUserWithEmbedding({
    required String userId,
    required String name,
    required String email,
    required String faceId,
    required List<double> embedding,
    String? imagePath,
  }) async {
    try {
      final batch = _firestore.batch();

      // Save user data
      final userRef = _firestore.collection(usersCollection).doc(userId);
      batch.set(userRef, {
        'name': name,
        'email': email,
        'faceId': faceId,
        'imagePath': imagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save face embedding
      final embeddingRef = _firestore.collection(embeddingsCollection).doc(faceId);
      batch.set(embeddingRef, {
        'userId': userId,
        'embedding': embedding,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      log('✅ User and embedding saved to Firestore');
    } catch (e) {
      log('❌ Error saving to Firestore: $e');
      rethrow;
    }
  }

  /// Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return {'id': doc.id, ...doc.data()};
    } catch (e) {
      log('❌ Error getting user by email: $e');
      return null;
    }
  }

  /// Get user by face ID
  Future<Map<String, dynamic>?> getUserByFaceId(String faceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .where('faceId', isEqualTo: faceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return {'id': doc.id, ...doc.data()};
    } catch (e) {
      log('❌ Error getting user by faceId: $e');
      return null;
    }
  }

  /// Get face embedding by face ID
  Future<List<double>?> getFaceEmbedding(String faceId) async {
    try {
      final doc = await _firestore.collection(embeddingsCollection).doc(faceId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || !data.containsKey('embedding')) return null;

      final embeddingData = data['embedding'];
      if (embeddingData is List) {
        return embeddingData.map((e) => (e as num).toDouble()).toList();
      }
      return null;
    } catch (e) {
      log('❌ Error getting face embedding: $e');
      return null;
    }
  }

  /// Get all face embeddings for verification
  Future<Map<String, List<double>>> getAllFaceEmbeddings() async {
    try {
      final querySnapshot = await _firestore.collection(embeddingsCollection).get();

      final embeddings = <String, List<double>>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('embedding')) {
          final embeddingData = data['embedding'];
          if (embeddingData is List) {
            embeddings[doc.id] = embeddingData.map((e) => (e as num).toDouble()).toList();
          }
        }
      }
      return embeddings;
    } catch (e) {
      log('❌ Error getting all embeddings: $e');
      return {};
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      log('❌ Error getting all users: $e');
      return [];
    }
  }

  /// Delete user and their embedding
  Future<void> deleteUser(String userId, String faceId) async {
    try {
      final batch = _firestore.batch();

      final userRef = _firestore.collection(usersCollection).doc(userId);
      batch.delete(userRef);

      final embeddingRef = _firestore.collection(embeddingsCollection).doc(faceId);
      batch.delete(embeddingRef);

      await batch.commit();
      log('✅ User and embedding deleted from Firestore');
    } catch (e) {
      log('❌ Error deleting user: $e');
      rethrow;
    }
  }

  /// Update user info (without embedding)
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(usersCollection).doc(userId).update(data);
      log('✅ User updated in Firestore');
    } catch (e) {
      log('❌ Error updating user: $e');
      rethrow;
    }
  }

  /// Get user count
  Future<int> getUserCount() async {
    try {
      final querySnapshot = await _firestore.collection(usersCollection).get();
      return querySnapshot.docs.length;
    } catch (e) {
      log('❌ Error getting user count: $e');
      return 0;
    }
  }
}
