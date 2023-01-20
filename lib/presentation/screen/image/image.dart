import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImageState();
}

final picker = ImagePicker();

class _ImageState extends ConsumerState<ImageScreen> {
  File? file;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        final model = ref.read(flModelProvider);

        Interpreter interpreter = Interpreter.fromFile(model!.file);

        var _inputShape = interpreter.getInputTensor(0).shape;
        var _outputShape = interpreter.getOutputTensor(0).shape;
        var _outputType = interpreter.getOutputTensor(0).type;

        ImageProcessor imageProcessor = ImageProcessorBuilder().add(ResizeOp(_inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR)).build();
        final pickedImage = (await picker.pickImage(source: ImageSource.gallery, maxWidth: 560));
        if (pickedImage == null) {
          Navigator.of(context).pop();
          return;
        }
        file = File(pickedImage.path);
        TensorImage tensorImage = TensorImage.fromFile(file!);

        tensorImage = imageProcessor.process(tensorImage);

        TensorBuffer output0 = TensorBuffer.createFixedSize(interpreter.getOutputTensor(0).shape, interpreter.getOutputTensor(0).type);
        TensorBuffer output1 = TensorBuffer.createFixedSize(interpreter.getOutputTensor(1).shape, interpreter.getOutputTensor(1).type);

        var _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);

        interpreter.run(tensorImage.buffer, _outputBuffer.getBuffer());
        List<double> regression = output0.getDoubleList();
        List<double> classificators = output1.getDoubleList();
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image'),
      ),
      body: Center(
        child: file == null
            ? const Text('No image selected.')
            : SizedBox(
                width: size.width,
                height: size.height,
                child: Image.file(file!),
              ),
      ),
    );
  }
}
