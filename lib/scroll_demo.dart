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
            backgroundRoughness: 0.6,
            backgroundColor: Colors.lightBlueAccent,
            cameraOffset: const Offset(-40, -50),
            child: Center(
              child: ListView(
                children: [
                  _CardItem(
                    context,
                    Icons.flight_takeoff,
                    'Premium Business Class',
                    'Experience luxury at 35,000 feet with our newly upgraded business class. Enjoy lie-flat seats, gourmet dining, and exclusive lounge access. Perfect for your next business trip.',
                  ),
                  _CardItem(
                    context,
                    Icons.card_travel,
                    'Summer Vacation Deals',
                    'Book your summer getaway now and save up to 40% on selected routes. Our special summer packages include free checked baggage and priority boarding.',
                  ),
                  _CardItem(
                    context,
                    Icons.workspace_premium,
                    'Elite Status Benefits',
                    'Unlock exclusive privileges with our Elite Status program. Enjoy priority check-in, extra baggage allowance, and access to premium lounges worldwide. Start earning points today!',
                  ),
                ],
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

  Widget _CardItem(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: SizedBox(
        width: 300,
        height: 300,
        child: SpatialContainer(
          roughness: 0.4,
          sideRadius: 40,
          topRadius: 0,
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
                        roughness: 0.4,
                        sideRadius: 50,
                        topRadius: 20,
                        elevation: 300,
                        color: const Color(0xFF1E88E5),
                        sideColor: const Color(0xFF1565C0),
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
                          color: Color(0xFF1A237E),
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
