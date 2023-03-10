import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:image/image.dart' as image_lib;

final ModelManager modelManager = FirebaseObjectDetectorModelManager();

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImageState();
}

final picker = ImagePicker();

class _ImageState extends ConsumerState<ImageScreen> {
  File? file;

  List<DetectedObject> objects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        final model = ref.read(flModelProvider);

        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile == null) {
          Navigator.of(context).pop();
          return;
        }

        setState(() {
          file = File(pickedFile.path);
        });

        if (!(await modelManager.isModelDownloaded(model!.name))) {
          await modelManager.downloadModel(model.name);
        }

        final options = FirebaseObjectDetectorOptions(
          mode: DetectionMode.single,
          modelName: model.name,
          classifyObjects: true,
          multipleObjects: true,
        );

        final objectDetector = ObjectDetector(options: options);

        InputImage inputImage = InputImage.fromFile(file!);
        objects.clear();
        objects.addAll(await objectDetector.processImage(inputImage));
        setState(() {});
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    var screenH = max(size.height, size.width);
    var screenW = min(size.height, size.width);

    var screenRatio = screenH / screenW;
    return Scaffold(
      appBar: AppBar(
        title: Text('Results: ${objects.length}'),
      ),
      body: SizedBox.fromSize(
        size: size,
        child: Stack(
          children: [
            if (file != null)
              Image.file(
                file!,
              ),
            ...boundingBoxes(screenRatio, size),
          ],
        ),
      ),
    );
  }

  List<Widget> boundingBoxes(double previewRatio, Size screen) {
    if (objects.isEmpty) {
      return [];
    }

    image_lib.Image image = image_lib.decodeImage(file!.readAsBytesSync())!;

    final rendersize = Size(image.width.toDouble(), image.height.toDouble());

    final renderRation = rendersize.height / rendersize.width;

    return objects.map((result) {
      final renderRect = result.boundingBox;

      final renderObject = result.labels.first;

      return Positioned(
        left: renderRect.left + 30,
        top: renderRect.top + 20,
        width: renderRect.width,
        height: renderRect.height,
        child: Container(
          width: renderRect.width,
          height: renderRect.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  color: Colors.red,
                  child: Text(
                    "${renderObject.text} ${(renderObject.confidence * 100).toStringAsFixed(0)}%",
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
