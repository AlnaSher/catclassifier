import 'dart:io';

import 'package:camera/camera.dart';
import 'package:catclassifier/services/gallery_service.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final CameraDescription camera;
  CameraController? _controller;
  XFile? _imageFile; // Храним как XFile
  bool _isBusy = false;

  final GalleryService _galleryService = GalleryService();

  void setImageFile(XFile file) {
    _imageFile = file;
  }

  XFile? get imageFile => _imageFile;

  Future<XFile?> pickImageFromGallery() async {
  return await _galleryService.pickImageFromGallery();
}

  CameraService(this.camera);

  bool get isBusy => _isBusy;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller?.initialize();
  }

  Future<void> takePicture() async {
    if (_isBusy || !(_controller?.value.isInitialized ?? false)) return;
    
    _isBusy = true;
    try {
      _imageFile = await _controller!.takePicture();
    } finally {
      _isBusy = false;
    }
  }

  void clearImage() {
    _imageFile = null;
  }

  void dispose() {
    _controller?.dispose();
  }
}