import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';

class ButtonDemo extends StatelessWidget {
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 400,
          child: SpatialRenderer(
            backgroundMetallic: 1.0,
            backgroundRoughness: 0.6,
            backgroundColor: Colors.grey,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: SpatialContainer(
                  roughness: 0.4,
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
        const SizedBox(height: 20),
        const Text(
          '3D Button Demo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
