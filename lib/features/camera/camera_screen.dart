import 'dart:io';

import 'package:catclassifier/services/classifier_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/camera_service.dart';
import 'widgets/camera_preview.dart';
import 'widgets/camera_controls.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraService _cameraService;
  late final ClassifierService _classifierService;
  Map<String, double>? _classificationResults;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService(widget.camera);
    _classifierService = ClassifierService();
    _initServices();
  }

  Future<void> _initServices() async {
    await _cameraService.initialize();
    await _classifierService.init();
    if (mounted) setState(() {});
  }

  Future<void> _processImage(XFile? imageFile) async {
    if (imageFile == null) return;
    
    setState(() {
      _classificationResults = null;
      _cameraService.setImageFile(imageFile);  // Добавьте этот метод в CameraService
    });

    final results = await _classifierService.classifyImage(File(imageFile.path));
    
    if (mounted) {
      setState(() {
        _classificationResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Основное содержимое
          Column(
            children: [
              Expanded(
                child: _buildMainContent(),
              ),
              CameraControls(
                service: _cameraService,
                onImageTaken: _processImage,
                onImageCleared: () => setState(() => _classificationResults = null),
              ),
            ],
          ),
          
          // Результаты классификации
          if (_classificationResults != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildResultsCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_cameraService.imageFile != null) {
      return Stack(
        children: [
          Image.file(File(_cameraService.imageFile!.path)),
          if (_classificationResults == null)
            Center(child: CircularProgressIndicator()),
        ],
      );
    }
    return CameraPreviewWidget(service: _cameraService);
  }

  Widget _buildResultsCard() {
    final sortedResults = _classificationResults!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Результаты классификации:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...sortedResults.take(3).map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _classifierService.dispose();
    super.dispose();
  }
}