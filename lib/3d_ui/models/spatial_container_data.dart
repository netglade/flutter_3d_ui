
import 'dart:core';
import 'dart:ui';

class SpatialContainerData{
  final double elevation;
  final double sideRadius;
  final double topRadius;
  final Color sideColor;
  final double metallic;
  final double roughness;
  final double reflectance;

  const SpatialContainerData({
    required this.elevation,
    required this.sideRadius,
    required this.topRadius,
    required this.sideColor,
    required this.metallic,
    required this.roughness,
    required this.reflectance,
  });
}