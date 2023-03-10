import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as image_lib;
import 'package:ottaa_object_detector/application/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';


class Classifier {
  Classifier({
    required this.interpreter,
  });

  final Interpreter interpreter;
  static const int inputSize = 640;

  ImageProcessor? imageProcessor;
  List<List<int>> outputShapes = [];
  List<TfLiteType> outputTypes = [];

  static const int clsNum = 80;
  static const double objConfTh = 0.20;
  static const double clsConfTh = 0.20;

  Future<void> loadModel() async {
    try {
      final outputTensors = interpreter.getOutputTensors();

      for (final tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  /// image pre process
  TensorImage getProcessedImage(TensorImage inputImage) {
    final padSize = max(inputImage.height, inputImage.width);

    imageProcessor ??= ImageProcessorBuilder()
        .add(
          ResizeWithCropOrPadOp(padSize, padSize),
        )
        .add(
          ResizeOp(inputSize, inputSize, ResizeMethod.NEAREST_NEIGHBOUR),
        )
        .build();

    return imageProcessor!.process(inputImage);
  }

  List<Recognition> predict(image_lib.Image image) {
    var inputImage = TensorImage.fromImage(image);

    inputImage = getProcessedImage(inputImage);

    List<double> normalizedInputImage = [];
    for (var pixel in inputImage.tensorBuffer.getDoubleList()) {
      normalizedInputImage.add(pixel / 255.0);
    }
    var normalizedTensorBuffer = TensorBuffer.createDynamic(TfLiteType.float32);
    normalizedTensorBuffer.loadList(normalizedInputImage, shape: [inputSize, inputSize, 3]);

    final inputs = [];

    TensorBuffer outputLocations = TensorBufferFloat(outputShapes[0]);

    interpreter.run(normalizedTensorBuffer.buffer, outputLocations.buffer);

    final recognitions = <Recognition>[];
    List<double> results = outputLocations.getDoubleList();

    print("${results.length}");

    for (var i = 0; i < results.length; i += 5 + clsNum) {
      if (results[i + 4] < objConfTh) continue;

      double maxClsConf = results.sublist(i + 5, i + 5 + clsNum - 1).reduce(max);

      if (maxClsConf < clsConfTh) continue;

      int cls = results.sublist(i + 5, i + 5 + clsNum - 1).indexOf(maxClsConf) % clsNum;
      Rect outputRect = Rect.fromCenter(
        center: Offset(
          results[i] * inputSize,
          results[i + 1] * inputSize,
        ),
        width: results[i + 2] * inputSize,
        height: results[i + 3] * inputSize,
      );
      Rect transformRect = imageProcessor!.inverseTransformRect(outputRect, image.height, image.width);

      print(displayLabels[cls]);

      final recog = Recognition(i, cls, maxClsConf, transformRect);

      recognitions.add(Recognition(i, cls, maxClsConf, transformRect));
    }

    return recognitions;
  }
}
