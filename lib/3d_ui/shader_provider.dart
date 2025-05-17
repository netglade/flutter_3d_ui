import 'dart:ui';

import 'package:flutter/material.dart';

class ShaderProvider extends ChangeNotifier {
  FragmentShader? _shader;
  bool _isShaderLoaded = false;

  FragmentShader? get shader => _shader;
  bool get isShaderLoaded => _isShaderLoaded;

  Future<void> loadShader() async {
    if (_isShaderLoaded) return;

    FragmentProgram program =
        await FragmentProgram.fromAsset('./shaders/ray_tracing.frag');
    _shader = program.fragmentShader();
    _isShaderLoaded = true;
    notifyListeners();
  }
}
