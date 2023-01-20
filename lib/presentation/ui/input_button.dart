import 'package:flutter/material.dart';

class InputButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const InputButton({super.key, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final maxSize = size.width > size.height ? size.width : size.height;


    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: Size.fromHeight(maxSize / 3),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: colorTheme.primary,
        padding: const EdgeInsets.all(20),
      ),
      onPressed: onPressed,
      child: Center(
        child: Icon(
          icon,
          size: maxSize * 0.1,
        ),
      ),
    );
  }
}
