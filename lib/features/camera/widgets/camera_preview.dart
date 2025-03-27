import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '/services/camera_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraService service;

  const CameraPreviewWidget({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.imageFile != null) {
      return Image.file(File(service.imageFile!.path));
    }
    
    if (service.controller?.value.isInitialized ?? false) {
      return CameraPreview(service.controller!);
    }
    
    return const Center(child: CircularProgressIndicator());
  }
}