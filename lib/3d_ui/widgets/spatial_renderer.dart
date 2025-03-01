import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:balatro_flutter/3d_ui/spatial_renderer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
    final currentOffset = (context.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero) ??
        Offset.zero;

    final spatialContainerData = _provider.spatialContainers.entries
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
          final offset = renderBox.localToGlobal(Offset.zero) - currentOffset;

          print(data);
          print(size);
          print(offset);
        })
        .whereType<SpatialContainerData>()
        .toList();

    print(spatialContainerData);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(value: _provider, child: widget.child);
  }
}
