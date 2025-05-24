import 'package:flutter/material.dart';
import 'package:flutter_3d_ui/3d_ui/shader_provider.dart';
import 'package:flutter_3d_ui/pages/button_demo.dart';
import 'package:flutter_3d_ui/pages/scroll_demo.dart';
import 'package:flutter_3d_ui/widgets/responsive_wrapper.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ShaderProvider(),
        ),
      ],
      child: MaterialApp(
        title: '3D UI in Flutter',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
          useMaterial3: true,
        ),
        home: const AppInner(),
      ),
    );
  }
}

class AppInner extends StatefulWidget {
  const AppInner({super.key});

  @override
  State<AppInner> createState() => _AppInnerState();
}

class _AppInnerState extends State<AppInner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ShaderProvider>().loadShader();
      FlutterNativeSplash.remove();
    });
  }

  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ScrollDemo(),
    ButtonDemo(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShaderProvider>(
      builder: (context, shaderProvider, child) {
        if (!shaderProvider.isShaderLoaded) {
          return const SizedBox.shrink();
        }
        return DefaultTextStyle(
          style: const TextStyle(
            color: Colors.black,
            decoration: TextDecoration.none,
            fontSize: 18,
          ),
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
                      icon: Icon(Icons.view_list),
                      label: 'Scroll Demo',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.touch_app),
                      label: 'Button Demo',
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
      },
    );
  }
}
