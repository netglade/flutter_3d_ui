import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:balatro_flutter/3d_ui/spatial_boundary_provider.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class SpatialBoundary extends StatefulWidget {
  final Widget child;

  SpatialBoundary({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpatialBoundaryState();

}

class _SpatialBoundaryState extends State<SpatialBoundary> {

  final SpatialBoundaryProvider _provider = SpatialBoundaryProvider();
  late Ticker _ticker;
  List<SpatialContainerData> _spatialContainerData = [];

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
    final currentOffset = (context.findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero) ?? Offset.zero;

    final spatialContainerData = _provider.spatialContainerKeys.map((key) {
      if (key.currentContext == null) {
        return null;
      }

      final RenderBox? renderBox = key.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) {
        return null;
      }

      final Element? element = key.currentContext as Element?;
      if (element == null) {
        return null;
      }
    
      // Get the widget and check its type
      final SpatialContainer? widget = element.widget as SpatialContainer?;
      if (widget == null) {
        return null;
      }

      return SpatialContainerData(
        size: renderBox.size,
        offset: renderBox.localToGlobal(Offset.zero) - currentOffset,
        elevation: widget.elevation,
        sideRadius: widget.sideRadius,
        topRadius: widget.topRadius,
        sideColor: widget.sideColor,
        metallic: widget.metallic,
        roughness: widget.roughness,
        reflectance: widget.reflectance,
      );
    }).whereType<SpatialContainerData>().toList();

    setState(() => _spatialContainerData = spatialContainerData);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(value: _provider, 
      child: SpatialRenderer(child: widget.child, spatialContainerData: _spatialContainerData)
    );
  }
}
