import 'package:flutter/material.dart';

class MiloLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;

  const MiloLogo({
    super.key,
    this.width = 140,
    this.height = 140,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      color: color,
    );
  }
}
