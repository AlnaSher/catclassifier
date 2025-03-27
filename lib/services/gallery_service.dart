import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class GalleryService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка выбора нескольких изображений: $e');
      }
      return [];
    }
  }
}