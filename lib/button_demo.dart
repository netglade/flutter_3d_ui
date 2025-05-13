import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';

class ButtonDemo extends StatefulWidget {
  const ButtonDemo({super.key});

  @override
  State<ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<ButtonDemo> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 400,
          child: SpatialRenderer(
            enabled: _enabled,
            backgroundMetallic: 1.0,
            backgroundRoughness: 0.6,
            backgroundColor: Colors.grey,
            cameraOffset: const Offset(-40, -50),
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: SpatialContainer(
                  roughness: 0.4,
                  sideRadius: 70,
                  topRadius: 20,
                  elevation: 400,
                  color: Colors.red,
                  sideColor: Colors.red,
                  child: const Center(
                    child: Text(
                      'PUSH',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _enabled = !_enabled;
            });
          },
          child: Text(_enabled ? 'Disable 3D' : 'Enable 3D'),
        ),
      ],
    );
  }
}
