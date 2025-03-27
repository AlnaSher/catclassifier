import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  late Interpreter _interpreter;
  final List<String> _labels = [
    'Абиссинская', 
    'Американский бобтейл',
    'Американский кёрл',
    'Американская короткошерстная',
    'Бенгальская',
    'Бирманская',
    'Бомбейская',
    'Британская короткошерстная',
    'Египетский мау',
    'Экзотическая короткошерстная',
    'Мейн-кун',
    'Мэнкс',
    'Норвежская лесная',
    'Не удалось найти кошку',
    'Персинская',
    'Рэгдолл',
    'Русская голубая',
    'Шотландская вислоухая',
    'Сиамская',
    'Сфинкс',
    'Турецкая ангора'
    // добавьте все ваши породы
  ];

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      if (kDebugMode) {
        print('Модель успешно загружена');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки модели: $e');
      }
    }
  }

  Future<Map<String, double>> classifyImage(File imageFile) async {
    try {
      // 1. Преобразование изображения
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final imageMatrix = _imageToMatrix(resizedImage);

      // 2. Подготовка выходного буфера
      final output = List<double>.filled(_labels.length, 0.0);
      final outputBuffer = [output];

      // 3. Запуск модели с явным приведением типов
      _interpreter.run([imageMatrix], outputBuffer);

      // 4. Обработка результатов
      final results = _processOutput(outputBuffer[0]);

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка классификации: $e');
      }
      return {};
    }
  }

  List<List<List<double>>> _imageToMatrix(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    return List.generate(224, (y) {
      return List.generate(224, (x) {
        final pixel = resized.getPixel(x, y);
        return [
          (pixel.r - 127.5) / 127.5,   // Красный канал
          (pixel.g - 127.5) / 127.5,   // Зеленый канал
          (pixel.b - 127.5) / 127.5    // Синий канал
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
    _interpreter.close();
  }
}