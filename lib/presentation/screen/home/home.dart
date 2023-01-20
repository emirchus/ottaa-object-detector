import 'dart:developer';
import 'dart:io';

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecle_downloads_path_provider/constants/downloads_directory_type.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:ottaa_object_detector/application/providers/fl_model_provider.dart';
import 'package:ottaa_object_detector/main.dart';
import 'package:ottaa_object_detector/presentation/ui/input_button.dart';
import 'package:ottaa_object_detector/presentation/ui/loading_modal.dart';
import 'package:ottaa_ui_kit/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _onSubmit(String name) async {
    name = name.trim();
    final currentModel = ref.read(flModelProvider);
    log(currentModel?.file.path ?? "");
    if (name.trim().isEmpty || name == currentModel?.name) return;

    await LoadingModal.show(context, future: () async {
      try {
        final model = await FirebaseModelDownloader.instance.getModel(
          name,
          FirebaseModelDownloadType.localModel,
          FirebaseModelDownloadConditions(
            androidWifiRequired: true,
          ),
        );

        ref.read(flModelProvider.notifier).setModel(model);

        print(model.file);

        Directory downloadsDirectory = (await DownloadsPath.downloadsDirectory())!;

        File fileLabels = File("${downloadsDirectory.path}/labels.txt");

        await Tflite.loadModel(model: model.file.path, labels: fileLabels.path, isAsset: false);
      } on Exception catch (e) {
        debugPrint("Error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final model = ref.watch(flModelProvider);

    return Scaffold(
      appBar: const OTTAAAppBar(
        title: Text("OTTAA Object Detector"),
      ),
      body: SizedBox.fromSize(
        size: size,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Name of the model",
                  ),
                  onSubmitted: _onSubmit,
                ),
                const SizedBox(
                  height: 20,
                ),
                InputButton(
                  onPressed: (model == null || kCameras.isEmpty)
                      ? null
                      : () {
                          Navigator.of(context).pushNamed("/camera");
                        },
                  icon: Icons.camera_alt,
                ),
                const SizedBox(
                  height: 20,
                ),
                InputButton(
                  onPressed: model == null
                      ? null
                      : () {
                          Navigator.of(context).pushNamed("/image");
                        },
                  icon: Icons.image,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
