import 'package:flutter/material.dart';
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

    return Column(
      children: [
        SizedBox(
          height: 570,
          child: SpatialRenderer(
            enabled: enabled.value,
            backgroundRoughness: 0.6,
            backgroundColor: Colors.grey,
            child: Stack(
              children: [
                Center(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        scrollPosition.value = notification.metrics.pixels;
                      }
                      return false;
                    },
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 80),
                        _cardItem(
                          context,
                          Icons.window_rounded,
                          'Reflection',
                          'In the bottom the cards are emerging from a reflective surface, creating a realistic reflection effect. The reflection is dynamically updated based on the card\'s position and orientation.',
                        ),
                        _cardItem(
                          context,
                          Icons.light_mode,
                          'Directional Shadows',
                          'Shadows dynamically respond to the viewing angle, creating a sense of depth and dimension. The shadow direction and intensity change as you interact with the interface.',
                        ),
                        _cardItem(
                          context,
                          Icons.texture,
                          'Material Properties',
                          'Each surface has unique material properties like roughness and reflectivity. These properties determine how light interacts with the surface, creating realistic material effects.',
                        ),
                        const SizedBox(height: 90),
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
                    color: Colors.grey,
                    sideColor: Colors.black,
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
                    color: Colors.grey,
                    sideColor: const Color.fromARGB(255, 122, 122, 122),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                max: 650,
                label: scrollPosition.value.toStringAsFixed(0),
                onChanged: (value) {
                  scrollController.jumpTo(value);
                  scrollPosition.value = value;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardItem(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
      child: SizedBox(
        width: 300,
        height: 300,
        child: SpatialContainer(
          roughness: 0.1,
          sideRadius: 70,
          topRadius: 15,
          elevation: 200,
          color: Colors.white,
          sideColor: Colors.white,
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
                        color: Colors.blue,
                        sideColor: Colors.blue,
                        child: Icon(
                          icon,
                          color: Colors.white,
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
                          color: Colors.black,
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
