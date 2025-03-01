import 'dart:ui';

import 'package:balatro_flutter/3d_ui/spatial_renderer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:provider/provider.dart';

class SpatialRenderer extends StatefulWidget {
  final Widget child;

  SpatialRenderer({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpatialRendererState();
}

class _SpatialRendererState extends State<SpatialRenderer> {
  final SpatialBoundaryProvider _provider = SpatialBoundaryProvider();
  late Ticker _ticker;
  FragmentShader? _shader = null;

  static const int _maxShapes = 5;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (_shader == null) {
      return;
    }

    final currentOffset = (context.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero) ??
        Offset.zero;

    final shapeData = _provider.spatialContainers.entries
        .map((entry) {
          var key = entry.key;
          if (key.currentContext == null) {
            return null;
          }

          final RenderBox? renderBox =
              key.currentContext!.findRenderObject() as RenderBox?;
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
    }, initialIndex: 2);
    setState(() => {});
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
            return const CircularProgressIndicator();
          }

          return ChangeNotifierProvider.value(
              value: _provider,
              child: LayoutBuilder(builder: (context, constraints) {
                _shader!.setFloat(0, constraints.maxWidth);
                _shader!.setFloat(1, constraints.maxHeight);

                return AnimatedSampler((image, size, canvas) {
                  _shader!.setImageSampler(0, image);
                  final paint = Paint()..shader = _shader!;
                  canvas.drawRect(
                    Rect.fromLTWH(0, 0, size.width, size.height),
                    paint,
                  );
                }, child: widget.child);
              }));
        });
  }
}
