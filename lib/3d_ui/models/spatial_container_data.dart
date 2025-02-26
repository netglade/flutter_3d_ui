
import 'dart:core';
import 'dart:ui';

class SpatialContainerData{
  final Size size;
  final Offset offset;
  final double elevation;
  final double sideRadius;
  final double topRadius;
  final Color sideColor;
  final double metallic;
  final double roughness;
  final double reflectance;

  SpatialContainerData({
    required this.size,
    required this.offset,
    required this.elevation,
    required this.sideRadius,
    required this.topRadius,
    required this.sideColor,
    required this.metallic,
    required this.roughness,
    required this.reflectance,
  });
}