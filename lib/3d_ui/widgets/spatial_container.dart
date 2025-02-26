
import 'package:balatro_flutter/3d_ui/spatial_boundary_provider.dart';
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

  const SpatialContainer(this.child, {
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
}

class SpatialContainerState extends State<SpatialContainer> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spatialBoundaryProvider = Provider.of<SpatialBoundaryProvider>(context, listen: false);
      spatialBoundaryProvider.registerSpatialContainerKey(_key);
    });
  }

  @override
  void dispose() {
    final spatialBoundaryProvider = Provider.of<SpatialBoundaryProvider>(context, listen: false);
    spatialBoundaryProvider.unregisterSpatialContainerKey(_key);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: BoxDecoration(
      color: widget.color,
      borderRadius: BorderRadius.circular(widget.sideRadius),
    ), child: widget.child);
  }
}