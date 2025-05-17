import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double mobileWidth;
  final double mobileHeight;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.mobileWidth = 410,
    this.mobileHeight = 810,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (isMobile) {
      return child;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.2, 0.0),
          radius: 1.5,
          colors: [
            Color.fromARGB(255, 212, 221, 227),
            Color.fromARGB(255, 99, 134, 169),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25.0),
              child: Container(
                width: mobileWidth,
                height: mobileHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 8,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
