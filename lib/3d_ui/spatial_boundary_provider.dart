import 'package:balatro_flutter/3d_ui/models/spatial_container_data.dart';
import 'package:flutter/material.dart';

class SpatialBoundaryProvider extends ChangeNotifier {
  final Set<GlobalKey> _spatialContainerKeys = {};

  Set<GlobalKey> get spatialContainerKeys => _spatialContainerKeys;

  void registerSpatialContainerKey(GlobalKey key) {
    _spatialContainerKeys.add(key);
  }

  void unregisterSpatialContainerKey(GlobalKey key) {
    _spatialContainerKeys.remove(key);
  }
}