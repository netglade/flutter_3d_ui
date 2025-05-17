import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_3d_ui/3d_ui/widgets/spatial_container.dart';
import 'package:flutter_3d_ui/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ButtonDemo extends HookWidget {
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = useState(true);
    final roughness = useState(0.4);
    final topRadius = useState(20.0);
    final sideRadius = useState(70.0);

    // Create animation controller for elevation
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 500),
      initialValue: 400.0,
    );

    final elevationAnimation = useAnimation(
        Tween<double>(begin: 200.0, end: 400.0).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    )));

    void handlePress() {
      // Immediately jump to 200 by setting controller to beginning value
      animationController.value = 0.0;
      // Then animate from 200 back to 400
      animationController.forward();
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: SpatialRenderer(
            enabled: enabled.value,
            backgroundRoughness: 0.6,
            backgroundColor: Colors.grey,
            child: Center(
              child: SizedBox(
                width: 206,
                height: 206,
                child: GestureDetector(
                  onTapDown: (_) => handlePress(),
                  child: SpatialContainer(
                    roughness: roughness.value,
                    sideRadius: sideRadius.value,
                    topRadius: topRadius.value,
                    elevation: elevationAnimation,
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
        ),
        const SizedBox(height: 15),
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Roughness: ${roughness.value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: roughness.value,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: roughness.value.toStringAsFixed(2),
                onChanged: (value) {
                  roughness.value = value;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Side Radius: ${sideRadius.value.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: sideRadius.value,
                min: 0.0,
                max: 100.0,
                label: sideRadius.value.toStringAsFixed(0),
                onChanged: (value) {
                  sideRadius.value = value;
                  if (topRadius.value + 15.0 > value) {
                    topRadius.value = max(0.0, value - 15.0);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Top Radius: ${topRadius.value.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: topRadius.value,
                min: 0.0,
                max: min(50.0, max(0.0, sideRadius.value - 15.0)),
                label: topRadius.value.toStringAsFixed(0),
                onChanged: (value) {
                  topRadius.value = value;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
