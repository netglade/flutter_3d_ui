import 'package:flutter_3d_ui/pages/button_demo.dart';
import 'package:flutter_3d_ui/widgets/responsive_wrapper.dart';
import 'package:flutter_3d_ui/pages/scroll_demo.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D UI in Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ButtonDemo(),
    ScrollDemo(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
          color: Colors.black, decoration: TextDecoration.none, fontSize: 18),
      child: ColoredBox(
        color: Colors.white,
        child: ResponsiveWrapper(
          child: Scaffold(
            body: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.touch_app),
                  label: 'Button Demo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_list),
                  label: 'Scroll Demo',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
