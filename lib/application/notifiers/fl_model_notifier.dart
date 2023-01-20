import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlModelNotifier extends StateNotifier<FirebaseCustomModel?> {
  FlModelNotifier() : super(null);

  Future<void> getModel(String name) async {
    state = await FirebaseModelDownloader.instance.getModel(
      name,
      FirebaseModelDownloadType.localModel,
      FirebaseModelDownloadConditions(
        androidWifiRequired: true,
      ),
    );
  }

  void clear() => state = null;

  void setModel(FirebaseCustomModel? model) => state = model;

  FirebaseCustomModel get model => state!;
}
