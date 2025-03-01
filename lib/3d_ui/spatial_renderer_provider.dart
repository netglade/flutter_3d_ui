import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:flutter/material.dart';

class SpatialBoundaryProvider extends ChangeNotifier {
  final Map<GlobalKey, SpatialContainerData> _spatialContainers = {};

  Map<GlobalKey, SpatialContainerData> get spatialContainers =>
      _spatialContainers;

  void addOrUpdateSpatialContainer(GlobalKey key, SpatialContainerData data) {
    _spatialContainers[key] = data;
  }

  void unregisterSpatialContainer(GlobalKey key) {
    _spatialContainers.remove(key);
  }
}
