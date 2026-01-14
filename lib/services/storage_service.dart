import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService instance = StorageService._init();

  StorageService._init();

  /// Save face image to local storage
  Future<String> saveFaceImage(String sourcePath, String faceId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final faceImagesDir = Directory('${directory.path}/face_images');

      // Create directory if it doesn't exist
      if (!await faceImagesDir.exists()) {
        await faceImagesDir.create(recursive: true);
      }

      // Copy image to permanent location
      final fileName = '$faceId.jpg';
      final savedPath = '${faceImagesDir.path}/$fileName';
      final sourceFile = File(sourcePath);
      await sourceFile.copy(savedPath);

      log('✅ Face image saved to: $savedPath');
      return savedPath;
    } catch (e) {
      log('❌ Error saving face image: $e');
      rethrow;
    }
  }

  /// Get face image path by face ID
  Future<String?> getFaceImagePath(String faceId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/face_images/$faceId.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        return imagePath;
      }
      return null;
    } catch (e) {
      log('❌ Error getting face image: $e');
      return null;
    }
  }

  /// Delete face image by face ID
  Future<void> deleteFaceImage(String faceId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/face_images/$faceId.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        await file.delete();
        log('✅ Face image deleted: $imagePath');
      }
    } catch (e) {
      log('❌ Error deleting face image: $e');
    }
  }
}
