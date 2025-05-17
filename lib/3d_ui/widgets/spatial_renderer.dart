import 'dart:ui';

import 'package:balatro_flutter/3d_ui/spatial_renderer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:provider/provider.dart';

class SpatialRenderer extends StatefulWidget {
  final Widget child;
  final Color lightColor;
  final double lightIntensity;
  final Color skyColor;
  final Color backgroundColor;
  final Vector3 lightDirection;
  final double cameraHeight;
  final Vector3 rayDirection;
  final double indirectLightStrength;
  final double backgroundRoughness;
  final double backgroundMetallic;
  final double backgroundReflectance;
  final bool enabled;
  final Offset cameraOffset;

  /// Creates a 3D renderer for the given [child] widget.
  ///
  /// The renderer uses ray tracing to create realistic lighting and shadows.
  /// The scene is viewed from an orthographic camera positioned above the scene.
  /// The background is at z=0, and shapes extend upward based on their elevation.
  ///
  /// The [lightColor] determines the color of the light source.
  /// The [lightIntensity] sets the strength of the light.
  /// The [skyColor] and [backgroundColor] define the scene's background colors.
  /// The [lightDirection] should point downward with a negative z component.
  /// The [cameraHeight] sets how far above the scene the camera is positioned.
  /// The [rayDirection] determines the camera's viewing direction.
  /// The [indirectLightStrength] controls the strength of ambient/indirect lighting.
  /// The [backgroundRoughness] sets the roughness of the background material.
  /// The [backgroundMetallic] sets the metallic property of the background material.
  /// The [backgroundReflectance] sets the reflectance of the background material.
  /// The [enabled] parameter controls whether the 3D rendering is active.
  /// The [cameraOffset] allows shifting the camera's view position.
  SpatialRenderer({
    Key? key,
    required this.child,
    this.lightColor = const Color(0xFFFFFFFF),
    this.lightIntensity = 4.0,
    this.skyColor = const Color(0xDDDDFFFF),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.lightDirection = const Vector3(0.2, 0.2, -1.0),
    this.cameraHeight = 500.0,
    this.rayDirection = const Vector3(0.1, 0.1, -1.0),
    this.indirectLightStrength = 0.2,
    this.backgroundRoughness = 0.0,
    this.backgroundMetallic = 0.0,
    this.backgroundReflectance = 0.5,
    this.enabled = true,
    this.cameraOffset = Offset.zero,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpatialRendererState();
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);
}

class _SpatialRendererState extends State<SpatialRenderer> {
  final SpatialRendererProvider _provider = SpatialRendererProvider();
  FragmentShader? _shader = null;

  static const int _maxShapes = 8;

  bool firstFrameRendered = false;

  void _setShaderUniforms() {
    if (_shader == null) {
      return;
    }

    if (!firstFrameRendered) {
      firstFrameRendered = true;
      return;
    }

    final currentOffset = (context.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero) ??
        Offset.zero;

    // Set light and camera uniforms
    _shader!.setFloat(2, widget.lightColor.r);
    _shader!.setFloat(3, widget.lightColor.g);
    _shader!.setFloat(4, widget.lightColor.b);
    _shader!.setFloat(5, widget.lightIntensity);
    _shader!.setFloat(6, widget.skyColor.r);
    _shader!.setFloat(7, widget.skyColor.g);
    _shader!.setFloat(8, widget.skyColor.b);
    _shader!.setFloat(9, widget.backgroundColor.r);
    _shader!.setFloat(10, widget.backgroundColor.g);
    _shader!.setFloat(11, widget.backgroundColor.b);
    _shader!.setFloat(12, widget.lightDirection.x);
    _shader!.setFloat(13, widget.lightDirection.y);
    _shader!.setFloat(14, widget.lightDirection.z);
    _shader!.setFloat(15, widget.cameraHeight);
    _shader!.setFloat(16, widget.rayDirection.x);
    _shader!.setFloat(17, widget.rayDirection.y);
    _shader!.setFloat(18, widget.rayDirection.z);
    _shader!.setFloat(19, widget.indirectLightStrength);
    _shader!.setFloat(20, widget.backgroundRoughness);
    _shader!.setFloat(21, widget.backgroundMetallic);
    _shader!.setFloat(22, widget.backgroundReflectance);
    _shader!.setFloat(23, widget.cameraOffset.dx);
    _shader!.setFloat(24, widget.cameraOffset.dy);

    final shapeData = _provider.spatialContainers.entries
        .map((entry) {
          var key = entry.key;
          if (key.currentContext == null ||
              key.currentContext?.mounted == false) {
            return null;
          }

          final RenderBox? renderBox;
          try {
            renderBox = key.currentContext!.findRenderObject() as RenderBox?;
          } catch (e) {
            return null;
          }

          if (renderBox == null || !renderBox.hasSize) {
            return null;
          }

          final Element? element = key.currentContext as Element?;
          if (element == null) {
            return null;
          }

          final data = entry.value;
          final size = renderBox.size;
          final offset = renderBox.localToGlobal(Offset.zero) -
              currentOffset +
              Offset(size.width / 2.0, size.height / 2.0);

          return [
            offset.dx,
            offset.dy,
            size.width,
            size.height,
            data.elevation,
            data.sideRadius,
            data.topRadius,
            data.sideColor.r,
            data.sideColor.g,
            data.sideColor.b,
            data.metallic,
            data.roughness,
            data.reflectance,
          ];
        })
        .nonNulls
        .toList();

    final uniforms = [
      ...shapeData,
      ...List.filled(_maxShapes - shapeData.length, List.filled(13, 0.0))
    ].expand((element) => element).toList();

    _shader!.setFloatUniforms((setter) {
      setter.setFloats(uniforms);
    }, initialIndex: 25);
  }

  Future<void> _loadShader() async {
    FragmentProgram program =
        await FragmentProgram.fromAsset('./shaders/ray_tracing.frag');
    _shader = program.fragmentShader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadShader(),
        builder: (context, snapshot) {
          if (_shader == null) {
            return Center(
                child: Text(
              'Loading...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ));
          }

          return ChangeNotifierProvider.value(
              value: _provider,
              child: LayoutBuilder(builder: (context, constraints) {
                _shader!.setFloat(0, constraints.maxWidth);
                _shader!.setFloat(1, constraints.maxHeight);

                return AnimatedSampler(
                  enabled: widget.enabled,
                  (image, size, canvas) {
                    if (!firstFrameRendered) {
                      firstFrameRendered = true;
                      final paint = Paint()..color = Colors.white;
                      canvas.drawRect(
                        Rect.fromLTWH(0, 0, size.width, size.height),
                        paint,
                      );

                      // Draw loading text
                      final textPainter = TextPainter(
                        text: const TextSpan(
                          text: 'Loading...',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                      );
                      textPainter.layout();
                      textPainter.paint(
                        canvas,
                        Offset(
                          (size.width - textPainter.width) / 2,
                          (size.height - textPainter.height) / 2,
                        ),
                      );
                      return;
                    }

                    _shader!.setImageSampler(0, image);
                    _setShaderUniforms();

                    final paint = Paint()..shader = _shader!;
                    canvas.drawRect(
                      Rect.fromLTWH(0, 0, size.width, size.height),
                      paint,
                    );
                  },
                  child: ColoredBox(
                      color: widget.backgroundColor, child: widget.child),
                );
              }));
        });
  }
}
