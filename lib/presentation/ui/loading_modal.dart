import 'package:flutter/material.dart';
import 'package:ottaa_object_detector/presentation/ui/animated_dialog.dart';

typedef FutureVoidCallback = Future<void> Function();

class LoadingModal extends StatefulWidget {
  final FutureVoidCallback? future;

  const LoadingModal({super.key, this.future});

  static Future<T?> show<T>(
    BuildContext context, {
    Future<void> Function()? future,
  }) async {
    return AnimatedDialog.animate<T>(context, LoadingModal(future: future));
  }

  @override
  State<LoadingModal> createState() => _LoadingModalState();
}

class _LoadingModalState extends State<LoadingModal> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (widget.future != null) {
        await widget.future!();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
