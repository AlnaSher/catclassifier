import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> init() async {
    try {
      // 1. Загрузка модели
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      
      // 2. Загрузка меток из JSON
      await _loadLabels();
      
      if (kDebugMode) {
        print('Модель успешно загружена');
        print('Количество классов: ${_labels.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации: $e');
      }
      rethrow;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/class_indices.json');
      final Map<String, dynamic> classIndices = json.decode(jsonString);
      
      // Сортируем метки по индексам
      _labels = List.filled(classIndices.length, '');
      classIndices.forEach((label, index) {
        _labels[index] = label;
      });
      
      if (kDebugMode) {
        print('Загружены метки классов: $_labels');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки меток: $e');
      }
      _labels = []; // Фолбек на случай ошибки
      rethrow;
    }
  }

  Future<Map<String, double>> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      throw Exception('Классификатор не инициализирован');
    }

    try {
      // 1. Преобразование изображения
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Не удалось декодировать изображение');

      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final imageMatrix = _imageToMatrix(resizedImage);

      // 2. Подготовка выходного буфера
      final output = List<double>.filled(_labels.length, 0.0);
      final outputBuffer = [output];

      // 3. Запуск модели
      _interpreter.run([imageMatrix], outputBuffer);

      // 4. Обработка результатов
      return _processOutput(outputBuffer[0]);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка классификации: $e');
      }
      rethrow;
    }
  }

  List<List<List<double>>> _imageToMatrix(img.Image image) {
    return List.generate(224, (y) {
      return List.generate(224, (x) {
        final pixel = image.getPixel(x, y);
        return [
          pixel.r / 255.0,  // Нормализация [0,1]
          pixel.g / 255.0,
          pixel.b / 255.0
        ];
      });
    });
  }

  Map<String, double> _processOutput(List<double> output) {
    final results = <String, double>{};
    for (var i = 0; i < _labels.length; i++) {
      results[_labels[i]] = output[i];
    }
    return results;
  }

  void dispose() {
    _interpreter?.close();
  }
}