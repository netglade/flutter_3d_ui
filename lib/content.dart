import 'package:flutter/material.dart';

class AceCard extends StatelessWidget {
  const AceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Column(children: [
                  Text(
                    "A",
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    "♠",
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ]),
              ),
              const Expanded(
                // Add Expanded to center the middle symbol
                child: Center(
                  child: Text(
                    "♠",
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.none,
                      fontSize: 100,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Column(children: [
                  Transform.rotate(
                    angle: 3.14,
                    child: const Text(
                      "♠",
                      style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: 3.14,
                    child: const Text(
                      "A",
                      style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
          Center(child: FlutterLogo(size: 1500,)),

        ],
      ),
    );
  }
}
