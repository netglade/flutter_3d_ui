import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';

class ScrollDemo extends StatelessWidget {
  const ScrollDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SpatialRenderer(
      backgroundMetallic: 1.0,
      backgroundRoughness: 0.6,
      backgroundColor: Colors.grey,
      child: Center(
        child: ListView(
          children: List.generate(
            4,
            (i) => Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: SpatialContainer(
                    roughness: i % 2 == 0 ? 1.0 : 0.4,
                    sideRadius: 70,
                    topRadius: 20,
                    elevation: 200,
                    color: Colors.amber,
                    sideColor: Colors.amber,
                    child: const Center(
                      child: Text('ahojky'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
