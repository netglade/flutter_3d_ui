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
      home: ColoredBox(
        color: Colors.lightBlue,
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..rotateX(0.3) // tilt on X axis
                      ..rotateY(-0.4), // tilt on Y axis
                    alignment: Alignment.center,
                    child: Container(
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 0,
                            offset: Offset(20, 20),
                          ),
                        ],
                      ),
                      child: Text('hi'),
                    ),
                  ),
                ))),
      ),
    );
  }
}
