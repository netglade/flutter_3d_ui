import 'dart:math';

import 'package:flutter/material.dart' hide Colors;
import 'package:flutter_3d_ui/3d_ui/models/vector3.dart';
import 'package:flutter_3d_ui/3d_ui/widgets/spatial_container.dart';
import 'package:flutter_3d_ui/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScrollDemo extends HookWidget {
  const ScrollDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = useState(true);
    final scrollController = useScrollController();
    final scrollPosition = useState(0.0);
    final lightDirection = useState(0.0);

    final lightDirection1 = Vector3(0.2, 0.2, -1.0); // Right
    final lightDirection2 = Vector3(0.2, -0.07, -1.0); // Left

    final interpolatedDirection = Vector3(
      lightDirection1.x +
          (lightDirection2.x - lightDirection1.x) * lightDirection.value,
      lightDirection1.y +
          (lightDirection2.y - lightDirection1.y) * lightDirection.value,
      lightDirection1.z +
          (lightDirection2.z - lightDirection1.z) * lightDirection.value,
    );

    return Column(
      children: [
        SizedBox(
          height: 490,
          child: SpatialRenderer(
            enabled: enabled.value,
            backgroundRoughness: 0.6,
            backgroundColor: const Color(0xFF9E9E9E),
            lightDirection: interpolatedDirection,
            child: Stack(
              children: [
                Center(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        scrollPosition.value =
                            min(notification.metrics.pixels, 630);
                      }
                      return false;
                    },
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 59),
                        _CardItem(
                          key: const ValueKey('reflection'),
                          context: context,
                          icon: Icons.window_rounded,
                          title: 'Reflection',
                          subtitle:
                              'In the bottom the cards are emerging from a reflective surface, creating a realistic reflection effect. The reflection is dynamically updated based on the card\'s position and orientation.',
                        ),
                        _CardItem(
                          key: const ValueKey('shadows'),
                          context: context,
                          icon: Icons.light_mode,
                          title: 'Directional Shadows',
                          subtitle:
                              'Shadows dynamically respond to the viewing angle, creating a sense of depth and dimension. The shadow direction and intensity change as you interact with the interface.',
                        ),
                        _CardItem(
                          key: const ValueKey('material'),
                          context: context,
                          icon: Icons.texture,
                          title: 'Material Properties',
                          subtitle:
                              'Each surface has unique material properties like roughness and reflectivity. These properties determine how light interacts with the surface, creating realistic material effects.',
                        ),
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -50,
                  left: -100,
                  right: -50,
                  child: SpatialContainer(
                    roughness: 0.4,
                    sideRadius: 0,
                    topRadius: 0,
                    elevation: 900,
                    color: const Color(0xFF9E9E9E),
                    sideColor: const Color.fromARGB(255, 70, 70, 70),
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  right: -50,
                  child: SpatialContainer(
                    roughness: 0.4,
                    sideRadius: 0,
                    topRadius: 0,
                    elevation: 900,
                    color: const Color(0xFF9E9E9E),
                    sideColor: const Color(0xFF7A7A7A),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scroll Position: ${scrollPosition.value.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: scrollPosition.value,
                min: 0.0,
                max: 630,
                label: scrollPosition.value.toStringAsFixed(0),
                onChanged: (value) {
                  scrollController.jumpTo(value);
                  scrollPosition.value = value;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Light Direction',
                style: const TextStyle(fontSize: 18),
              ),
              Slider(
                value: lightDirection.value,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  lightDirection.value = value;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardItem extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardItem({
    super.key,
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
      child: SizedBox(
        width: 300,
        height: 300,
        child: SpatialContainer(
          roughness: 0.1,
          sideRadius: 70,
          topRadius: 15,
          elevation: 200,
          color: const Color(0xFFFFFFFF),
          sideColor: const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: SpatialContainer(
                        roughness: 0.45,
                        sideRadius: 45,
                        topRadius: 10,
                        elevation: 300,
                        color: const Color(0xFF2196F3),
                        sideColor: const Color(0xFF2196F3),
                        child: Icon(
                          icon,
                          color: const Color(0xFFFFFFFF),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF455A64),
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
