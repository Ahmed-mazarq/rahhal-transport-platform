import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class LocalImageService {
  final Uuid _uuid = const Uuid();

  Future<String> saveImageLocally(
    File imageFile, {
    String prefix = 'img',
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = path.extension(imageFile.path);
      final fileName = '${prefix}_${_uuid.v4()}$extension';

      final savedImagePath = path.join(directory.path, fileName);
      await imageFile.copy(savedImagePath);

      return savedImagePath;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  Future<bool> deleteImageLocally(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }
}
