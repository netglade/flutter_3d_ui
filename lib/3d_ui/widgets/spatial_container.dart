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

  /// Creates a container that renders its [child] in 3D space with lighting and shadows.
  ///
  /// The container uses PBR (Physically Based Rendering) for realistic materials.
  /// Material properties are controlled by [metallic], [roughness], and [reflectance].
  /// For detailed information about these properties, see the [Filament Material Properties Guide](https://google.github.io/filament/Material%20Properties.pdf).
  ///
  /// The [color] parameter sets the main color of the container, similar to a normal
  /// Flutter container's color. The [sideColor] parameter sets the color of the vertical
  /// sides of the container that are perpendicular to the display plane.
  ///
  /// The [sideRadius] works like a normal Flutter container's borderRadius - it rounds
  /// the corners of the container's base. The [topRadius] controls the rounding of the
  /// top edges, which is useful for creating rounded-top buttons or cards.
  ///
  /// The [elevation] determines how many pixels high the container appears to be
  /// raised from the background.
  const SpatialContainer({
    required this.child,
    Key? key,
    this.elevation = 8.0,
    this.sideRadius = 0.0,
    this.topRadius = 0.0,
    this.color,
    required this.sideColor,
    this.metallic = 0.0,
    this.roughness = 1.0,
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
    return Padding(
      key: _key,
      padding: EdgeInsets.all(1.0),
      child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.sideRadius),
          ),
          child: widget.child),
    );
  }
}
