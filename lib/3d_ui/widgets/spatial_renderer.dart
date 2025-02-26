
import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:flutter/material.dart';

class SpatialRenderer extends StatelessWidget {
  final Widget child;
  final List<SpatialContainerData> spatialContainerData ;

  const SpatialRenderer({Key? key, required this.child, required this.spatialContainerData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}