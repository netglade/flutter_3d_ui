import 'dart:ui';

class ShapeData {
  final double x;
  final double y;
  final double width;
  final double height;
  final double elevation;
  final double sideRadius;
  final double topRadius;
  final Color sideColor;

  ShapeData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.elevation,
    required this.sideRadius,
    required this.topRadius,
    required this.sideColor,
  });

  // Convert to float array for uniform buffer
  List<double> getData() {
    return [
      x, y, // position (vec2)
      width, height, // size (vec3)
      elevation,
      sideRadius, // sideRadius (float)
      topRadius, // topRadius (float)
      sideColor.r, // sideColor (vec3)
      sideColor.g,
      sideColor.b,
    ];
  }

  static int get stride => 10;
}
