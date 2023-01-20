import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/notifiers/fl_model_notifier.dart';

final flModelProvider = StateNotifierProvider<FlModelNotifier, FirebaseCustomModel?>((_) => FlModelNotifier());