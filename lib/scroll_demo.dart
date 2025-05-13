import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScrollDemo extends HookWidget {
  const ScrollDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = useState(true);

    return Column(
      children: [
        Container(
          height: 650,
          child: SpatialRenderer(
            enabled: enabled.value,
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
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text(
            '3D Effect',
            style: TextStyle(fontSize: 18),
          ),
          value: enabled.value,
          onChanged: (value) {
            enabled.value = value;
          },
        ),
      ],
    );
  }
}
