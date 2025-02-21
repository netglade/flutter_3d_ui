import 'dart:ui';

import 'package:balatro_flutter/ace_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class PixelatedCard extends StatelessWidget {
  const PixelatedCard({super.key});

  Future<FragmentShader> _loadShader() async {
    FragmentProgram program =
        await FragmentProgram.fromAsset('./shaders/pixelate.frag');
    return program.fragmentShader();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 400,
      child: LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<FragmentShader>(
            future: _loadShader(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final shader = snapshot.data!;
                shader.setFloat(
                    0, constraints.maxWidth); // Use constraint width
                shader.setFloat(
                    1, constraints.maxHeight); // Use constraint height

                return AnimatedSampler((image, size, canvas) {
                  shader.setImageSampler(0, image);
                  final paint = Paint()..shader = shader;
                  canvas.drawRect(
                    Rect.fromLTWH(0, 0, size.width, size.height),
                    paint,
                  );
                },
                    child:
                        Align(alignment: Alignment.topLeft, child: AceCard()));
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}
