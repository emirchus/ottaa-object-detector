import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/common/image_utils.dart';
import 'package:ottaa_object_detector/application/common/isolate_utils.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/application/tflite/classifier.dart';
import 'package:ottaa_object_detector/application/tflite/recognition.dart';
import 'package:ottaa_object_detector/main.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as image_lib;
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

  List<Recognition> results = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    final model = ref.read(flModelProvider);
    controller = CameraController(
      kCameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );
    print(model!.file);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Interpreter interpreter = Interpreter.fromFile(model.file);

      classifier = Classifier(interpreter: interpreter);
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

    final isolateCamImgData = IsolateData(
      height: cameraImage.height,
      width: cameraImage.width,
      image: ImageUtils.convertYUV420ToImage(
        cameraImage,
      ).getBytes(),
      interpreterAddress: classifier.interpreter.address,
    );

    var isolateData = await compute(inference, isolateCamImgData.toJson(), debugLabel: 'isolateCamImgData');

    var uiThreadInferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

    results.clear();
    results.addAll(isolateData);

    setState(() {
      predicting = false;
    });
  }

  static Future<List<Recognition>> inference(String isolateCamImgDataString) async {
    final isolateCamImgData = IsolateData.fromJson(isolateCamImgDataString);

    var image = image_lib.Image.fromBytes(
      isolateCamImgData.width,
      isolateCamImgData.height,
      isolateCamImgData.image,
    );

    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, 90);
    }

    final classifier = Classifier(
      interpreter: Interpreter.fromAddress(
        isolateCamImgData.interpreterAddress,
      ),
    );

    return classifier.predict(image);
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
      final renderRect = result.getRenderLocation(screen, previewRatio);

      return Positioned.fromRect(
        rect: renderRect,
        child: Container(
          width: renderRect.width,
          height: renderRect.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Colors.red,
                  child: Text(
                    "${result.displayLabel} ${(result.score * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
