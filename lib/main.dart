import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ottaa_object_detector/application/application.dart';
import 'package:ottaa_object_detector/firebase_options.dart';

List<CameraDescription> kCameras = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  kCameras.addAll(await availableCameras());

  runApp(
    const ProviderScope(child: Application()),
  );
}
