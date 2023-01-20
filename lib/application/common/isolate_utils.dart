import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:ottaa_object_detector/application/common/image_utils.dart';
import 'package:ottaa_object_detector/application/tflite/classifier.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort sendPort;

  Future<void> start() async {
    isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      if (isolateData != null) {
        Classifier classifier = Classifier(interpreter: Interpreter.fromAddress(isolateData.interpreterAddress));
        image_lib.Image? image = ImageUtils.convertCameraImage(isolateData.cameraImage);
        if (image == null) return;

        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image, 90);
        }
        Map<String, dynamic> results = classifier.predict(image);
        isolateData.responsePort?.send(results);
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  List<String> labels;
  SendPort? responsePort;

  IsolateData(this.cameraImage, this.interpreterAddress, this.labels, [this.responsePort]);
}
