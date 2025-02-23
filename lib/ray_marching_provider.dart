import 'dart:ui';

import 'package:balatro_flutter/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class RayMarchingProvider extends StatelessWidget {
  const RayMarchingProvider({super.key});

  Future<FragmentShader> _loadShader() async {
    FragmentProgram program =
        await FragmentProgram.fromAsset('./shaders/ray_marching.frag');
    return program.fragmentShader();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 420,
      child: LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<FragmentShader>(
            future: _loadShader(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final shader = snapshot.data!;
                shader.setFloat(0, constraints.maxWidth);
                shader.setFloat(1, constraints.maxHeight);

                return AnimatedSampler(
                  (image, size, canvas) {
                    shader.setImageSampler(0, image);
                    final paint = Paint()..shader = shader;
                    canvas.drawRect(
                      Rect.fromLTWH(0, 0, size.width, size.height),
                      paint,
                    );
                  },
                  child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: AceCard())),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}
