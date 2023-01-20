import 'package:flutter/material.dart';
import 'package:ottaa_object_detector/presentation/screen/camera/camera.dart';
import 'package:ottaa_object_detector/presentation/screen/home/home.dart';
import 'package:ottaa_object_detector/presentation/screen/image/image.dart';
import 'package:ottaa_ui_kit/theme.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "OTTAA Object Detector",
      theme: kOttaaLightThemeData,
      routes: {
        "/": (_) => const HomeScreen(),
        "/camera": (_) => const CameraScreen(),
        "/image": (_) => const ImageScreen(),
      },
      initialRoute: "/",
    );
  }
}
