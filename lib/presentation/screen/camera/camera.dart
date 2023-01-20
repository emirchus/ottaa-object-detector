import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/main.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraState();
}

class _CameraState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  late CameraController controller;

  bool predicting = false;

  List<Rect> boundingBoxes = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    final model = ref.read(flModelProvider);
    controller = CameraController(kCameras[0], ResolutionPreset.high);
    print(model!.file);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
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
            OverflowBox(
              maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
              maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
              child: CameraPreview(controller),
            ),
            ...getBoxes(screenW / previewH, previewSize),
          ],
        ),
      ),
    );
  }

  onLatestImageAvailable(CameraImage cameraImage) async {
    setState(() {
      predicting = true;
    });

    var startTime = DateTime.now().millisecondsSinceEpoch;

    var img = cameraImage;

    var recognitions = await Tflite.detectObjectOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      model: "YOLO",
    );

    int endTime = DateTime.now().millisecondsSinceEpoch;

    print("Detection took ${endTime - startTime}");

    setState(() {
      predicting = false;
    });
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

  List<Widget> getBoxes(double previewRatio, Size screen) {
    if (boundingBoxes.isEmpty) {
      return [];
    }
    return boundingBoxes.map((result) {
      return Positioned.fromRect(
        rect: result,
        child: Container(
          width: result.width,
          height: result.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
        ),
      );
    }).toList();
  }
}
