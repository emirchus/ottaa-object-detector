import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {});
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
