import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/common/isolate_utils.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/application/tflite/classifier.dart';
import 'package:ottaa_object_detector/application/tflite/recognition.dart';
import 'package:ottaa_object_detector/application/tflite/stats.dart';
import 'package:ottaa_object_detector/main.dart';
import 'dart:math' as math;

import 'package:tflite_flutter/tflite_flutter.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraState();
}

class _CameraState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  late CameraController controller;

  bool predicting = false;

  late Classifier classifier;

  late IsolateUtils isolateUtils = IsolateUtils();

  List<Recognition> results = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    final model = ref.read(flModelProvider);
    controller = CameraController(kCameras[0], ResolutionPreset.low);
    print(model!.file);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Interpreter interpreter = Interpreter.fromFile(model.file);

      classifier = Classifier(interpreter: interpreter);
      await isolateUtils.start();
      await controller.initialize();
      await controller.startImageStream(onLatestImageAvailable);
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    var screenH = math.max(size.height, size.width);
    var screenW = math.min(size.height, size.width);
    final previewSize = controller.value.previewSize!;
    var previewH = math.max(previewSize.height, previewSize.width);
    var previewW = math.min(previewSize.height, previewSize.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Scaffold(
      body: SizedBox.fromSize(
        size: size,
        child: Stack(
          children: [
            CameraPreview(controller),
            ...boundingBoxes(screenW / previewH, previewSize),
          ],
        ),
      ),
    );
  }

  onLatestImageAvailable(CameraImage cameraImage) async {
    setState(() {
      predicting = true;
    });

    var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

    var isolateData = IsolateData(cameraImage, classifier.interpreter.address, classifier.labels);

    Map<String, dynamic> inferenceResults = await inference(isolateData);

    var uiThreadInferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

    results.clear();
    results.addAll(inferenceResults["recognitions"]);

    print((inferenceResults["stats"] as Stats)..totalElapsedTime = uiThreadInferenceElapsedTime);

    setState(() {
      predicting = false;
    });
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        controller.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!controller.value.isStreamingImages) {
          await controller.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  List<Widget> boundingBoxes(double previewRatio, Size screen) {
    if (results.isEmpty) {
      return [];
    }
    return results.map((result) {
      final renderRect = result.renderLocation(previewRatio, screen)!;

      return Positioned.fromRect(
        rect: renderRect,
        child: Container(
          width: renderRect.width,
          height: renderRect.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
        ),
      );
    }).toList();
  }
}
