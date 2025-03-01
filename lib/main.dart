import 'package:balatro_flutter/3d_ui/widgets/spatial_container.dart';
import 'package:balatro_flutter/3d_ui/widgets/spatial_renderer.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DefaultTextStyle(
        style: TextStyle(
            color: Colors.black, decoration: TextDecoration.none, fontSize: 18),
        child: SpatialRenderer(
          child: Center(
            child: SpatialContainer(
              color: Colors.amber,
              sideColor: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('ahojky'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
