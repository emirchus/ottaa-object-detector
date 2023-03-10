import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/main.dart';
import 'dart:math' as math;

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraState();
}

class _CameraState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  late CameraController controller;

  bool predicting = false;

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

  List<Widget> boundingBoxes(double previewRatio, Size screen) {
    return [];
  }
}
