import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '/../services/camera_service.dart';

class CameraControls extends StatelessWidget {
  final CameraService service;
  final Function(XFile?) onImageTaken;
  final VoidCallback onImageCleared;

  const CameraControls({
    super.key,
    required this.service,
    required this.onImageTaken,
    required this.onImageCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await service.takePicture();
              onImageTaken(service.imageFile);
            },
            child: const Icon(Icons.camera),
          ),
          FloatingActionButton(
            onPressed: () async {
              final imageFile = await service.pickImageFromGallery();
              if (imageFile != null) {
                onImageTaken(imageFile);  // Убрано приведение типов as XFile?
              }
            },
            child: const Icon(Icons.photo_library),
          ),
          if (service.imageFile != null)
            FloatingActionButton(
              onPressed: () {
                service.clearImage();
                onImageCleared();
              },
              child: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }

  
}