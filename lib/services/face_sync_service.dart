import 'dart:developer';
import 'dart:math' as math;

import 'package:face_verification/face_verification.dart';

import 'firestore_service.dart';

/// Service to sync face embeddings between Firestore and local FaceVerification SDK
class FaceSyncService {
  static final FaceSyncService instance = FaceSyncService._init();

  FaceSyncService._init();

  /// Load all face embeddings from Firestore and register them with local FaceVerification
  /// This should be called on app startup to restore faces after reinstall
  Future<void> syncFromFirestore() async {
    try {
      log('🔄 Starting face sync from Firestore...');

      // Get all embeddings from Firestore
      final embeddings = await FirestoreService.instance.getAllFaceEmbeddings();

      if (embeddings.isEmpty) {
        log('ℹ️ No face embeddings found in Firestore');
        return;
      }

      log('📦 Found ${embeddings.length} face embeddings in Firestore');

      int syncedCount = 0;
      for (final entry in embeddings.entries) {
        final faceId = entry.key;
        final embedding = entry.value;

        try {
          // Check if already registered locally
          final isRegistered = await FaceVerification.instance.isFaceRegistered(faceId);

          if (!isRegistered) {
            // Register the face with the embedding from Firestore
            await FaceVerification.instance.registerFromEmbedding(
              id: faceId,
              embedding: embedding,
              imageId: 'synced_$faceId',
            );
            syncedCount++;
            log('✅ Synced face: $faceId');
          } else {
            log('ℹ️ Face already registered locally: $faceId');
          }
        } catch (e) {
          log('⚠️ Failed to sync face $faceId: $e');
        }
      }

      log('✅ Face sync complete. Synced $syncedCount new faces.');
    } catch (e) {
      log('❌ Face sync failed: $e');
    }
  }

  /// Calculate cosine similarity between two embedding vectors
  double calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Verify a face against all stored embeddings in Firestore
  /// Returns the matching faceId and similarity score, or null if no match
  Future<(String?, double)> verifyAgainstFirestore({
    required List<double> capturedEmbedding,
    double threshold = 0.85,
  }) async {
    try {
      final allEmbeddings = await FirestoreService.instance.getAllFaceEmbeddings();

      if (allEmbeddings.isEmpty) {
        log('ℹ️ No face embeddings found in Firestore for verification');
        return (null, 0.0);
      }

      String? bestMatchId;
      double bestSimilarity = 0.0;

      for (final entry in allEmbeddings.entries) {
        final similarity = calculateCosineSimilarity(capturedEmbedding, entry.value);
        log('📊 Similarity with ${entry.key}: ${(similarity * 100).toStringAsFixed(2)}%');

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatchId = entry.key;
        }
      }

      if (bestSimilarity >= threshold) {
        log(
          '✅ Best match: $bestMatchId with ${(bestSimilarity * 100).toStringAsFixed(2)}% similarity',
        );
        return (bestMatchId, bestSimilarity);
      }

      log(
        '❌ No match found above threshold ($threshold). Best was ${(bestSimilarity * 100).toStringAsFixed(2)}%',
      );
      return (null, bestSimilarity);
    } catch (e) {
      log('❌ Verification against Firestore failed: $e');
      return (null, 0.0);
    }
  }
}
