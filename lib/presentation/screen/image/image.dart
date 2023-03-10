import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ottaa_object_detector/application/common/isolate_utils.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/application/tflite/classifier.dart';
import 'package:ottaa_object_detector/application/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImageState();
}

final picker = ImagePicker();

class _ImageState extends ConsumerState<ImageScreen> {
  File? file;

  List<Recognition> results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        final model = ref.read(flModelProvider);

        Interpreter interpreter = Interpreter.fromFile(model!.file);

        Classifier classifier = Classifier(interpreter: interpreter);

        await classifier.loadModel();

        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile == null) {
          Navigator.of(context).pop();
          return;
        }

        setState(() {
          file = File(pickedFile.path);
        });

        final image = image_lib.decodeImage(file!.readAsBytesSync())!;

        final isolateCamImgData = IsolateData(
          width: image.width,
          height: image.height,
          image: image.getBytes(),
          interpreterAddress: classifier.interpreter.address,
        );

        var isolateData = await compute(inference, isolateCamImgData.toJson());

        setState(() {
          results = isolateData;
        });
      } catch (e) {
        print(e);
      }
    });
  }

  static Future<List<Recognition>> inference(String isolateCamImgDataString) async {
    final isolateCamImgData = IsolateData.fromJson(isolateCamImgDataString);

    var image = image_lib.Image.fromBytes(
      isolateCamImgData.width,
      isolateCamImgData.height,
      isolateCamImgData.image,
    );
    final classifier = Classifier(
      interpreter: Interpreter.fromAddress(
        isolateCamImgData.interpreterAddress,
      ),
    );

    await classifier.loadModel();

    return classifier.predict(image);
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
        title: Text('Results: ${results.length}'),
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
    if (results.isEmpty) {
      return [];
    }

    image_lib.Image image = image_lib.decodeImage(file!.readAsBytesSync())!;

    final rendersize = Size(image.width.toDouble(), image.height.toDouble());

    final renderRation = rendersize.height / rendersize.width;

    return results.map((result) {
      final renderRect = result.getRenderLocation(
        rendersize,
        renderRation / previewRatio,
      );

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
