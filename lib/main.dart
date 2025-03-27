import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Проверяем разрешения при запуске
  await _requestPermissions();
  
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  
  runApp(MyApp(camera: firstCamera));
}

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      // Для Android 13+
      await Permission.photos.request();
      await Permission.videos.request();
    }
  } else if (Platform.isIOS) {
    await Permission.photos.request();
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  
  const MyApp({super.key, required this.camera});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  
  const CameraScreen({super.key, required this.camera});
  
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  bool _isCameraReady = false;
  bool _isPermissionGranted = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    final status = await Permission.camera.status;
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
    
    if (_isPermissionGranted) {
      _initializeCamera();
    } else {
      await _requestPermissions();
      final newStatus = await Permission.camera.status;
      setState(() {
        _isPermissionGranted = newStatus.isGranted;
      });
      if (_isPermissionGranted) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
      print('Camera initialization error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) return;
    
    try {
      final image = await _controller.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to take picture')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Widget _buildCameraPreview() {
    if (!_isPermissionGranted) {
      return _buildPermissionDeniedView();
    }
    
    if (!_isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return CameraPreview(_controller);
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Camera permission required',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera App'),
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Реализация общего доступа к изображению
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageFile == null
                ? _buildCameraPreview()
                : Image.file(File(_imageFile!.path)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _isCameraReady ? _takePicture : null,
                  tooltip: 'Take Photo',
                  child: const Icon(Icons.camera),
                ),
                FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  tooltip: 'Pick from Gallery',
                  child: const Icon(Icons.photo_library),
                ),
                if (_imageFile != null)
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    tooltip: 'Retake',
                    child: const Icon(Icons.refresh),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}