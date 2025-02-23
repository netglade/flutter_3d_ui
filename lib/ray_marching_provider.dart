import 'dart:ui';

import 'package:balatro_flutter/content.dart';
import 'package:balatro_flutter/shape_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class RayMarchingProvider extends StatelessWidget {
  const RayMarchingProvider({super.key});

  static List<ShapeData> shapes = [
    ShapeData(
      x: 0.5,
      y: 0.5,
      width: 0.4,
      height: 0.2,
      elevation: 0.2,
      sideRadius: 0.05,
      topRadius: 0.0,
      sideColor: Colors.yellow,
    ),
    ShapeData(
      x: 0.4,
      y: 0.4,
      width: 0.4,
      height: 0.1,
      elevation: 0.2,
      sideRadius: 0.0,
      topRadius: 0.0,
      sideColor: Colors.blue,
    ),
  ];

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

                final uniformData = List<double>.filled(
                    shapes.length * ShapeData.stride, 0, growable: false);
                for (var i = 0; i < shapes.length; i++) {
                  final shapeData = shapes[i].getData();
                  uniformData.setAll(i * ShapeData.stride, shapeData);
                }

                shader.setFloatUniforms((setter) {
                    setter.setFloats(uniformData);
                  }, initialIndex: 2);


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
