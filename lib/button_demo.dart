import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ButtonDemo extends HookWidget {
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = useState(true);

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
        Container(
          height: 400,
          child: SpatialRenderer(
            enabled: enabled.value,
            backgroundMetallic: 1.0,
            backgroundRoughness: 0.6,
            backgroundColor: Colors.grey,
            cameraOffset: const Offset(-40, -50),
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: GestureDetector(
                  onTapDown: (_) => handlePress(),
                  child: SpatialContainer(
                    roughness: 0.4,
                    sideRadius: 70,
                    topRadius: 20,
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
            enabled.value = !enabled.value;
          },
          child: Text(enabled.value ? 'Disable 3D' : 'Enable 3D'),
        ),
      ],
    );
  }
}
