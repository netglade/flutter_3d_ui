import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:balatro_flutter/3d_ui/spatial_renderer_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpatialContainer extends StatefulWidget {
  final Widget child;
  final double elevation;
  final double sideRadius;
  final double topRadius;
  final Color? color;
  final Color sideColor;
  final double metallic;
  final double roughness;
  final double reflectance;

  const SpatialContainer({
    required this.child,
    Key? key,
    this.elevation = 8.0,
    this.sideRadius = 0.0,
    this.topRadius = 0.0,
    this.color,
    required this.sideColor,
    this.metallic = 0.0,
    this.roughness = 0.0,
    this.reflectance = 0.5,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SpatialContainerState();

  SpatialContainerData getData() {
    return SpatialContainerData(
      elevation: elevation,
      sideRadius: sideRadius,
      topRadius: topRadius,
      sideColor: sideColor,
      metallic: metallic,
      roughness: roughness,
      reflectance: reflectance,
    );
  }
}

class SpatialContainerState extends State<SpatialContainer> {
  final GlobalKey _key = GlobalKey();
  late SpatialRendererProvider _provider;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<SpatialRendererProvider>(context, listen: false);
      _provider.addOrUpdateSpatialContainer(_key, widget.getData());
    });
  }

  @override
  void dispose() {
    _provider.unregisterSpatialContainer(_key);

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpatialContainer oldWidget) {
    final spatialBoundaryProvider =
        Provider.of<SpatialRendererProvider>(context, listen: false);
    spatialBoundaryProvider.addOrUpdateSpatialContainer(_key, widget.getData());

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        key: _key,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.sideRadius),
        ),
        child: widget.child);
  }
}
