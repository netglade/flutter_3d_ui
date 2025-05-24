# 3D UI in Flutter

<p align='center'><b>An experimental project that turns Flutter UI into 3D using fragment shaders and ray tracing</b></p>


<p align='center'>
<a href="https://netglade.github.io/flutter_3d_ui/"><b>🎮 Live Demo</b></a> |
<a href="https://www.netglade.cz/en/blog/bringing-mcps-to-the-cloud-how-we-won-the-e2b-hackathon">📝 Blog Post (todo: url)</a>
</p>

<div align='center'>
  
[![Deploy Next.js site to Pages](https://github.com/netglade/flutter_3d_ui/actions/workflows/deploy.yml/badge.svg)](https://github.com/netglade/flutter_3d_ui/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

</div>


## About

The project uses a widget called `SpatialContainer` that lets you transform regular Flutter widgets into 3D objects with physically-based rendering properties. It's designed to be intuitive if you're already familiar with Flutter's `Container` widget.

```dart
SpatialContainer(
  // How high the element appears above the background (in pixels)
  elevation: 8.0,

  // Rounds the base corners (works like Flutter's borderRadius)
  sideRadius: 10.0,

  // Rounds the top edges of the 3D shape
  topRadius: 5.0,

  // Color of the vertical sides of the container
  sideColor: Colors.blue,

  // Material properties
  roughness: 0.3, // Lower = glossier, higher = more matte
  metallic: 0.0, // How metallic the surface appears
  reflectance: 0.5, // How reflective the surface is

  child: YourWidget(),
)

```

In addition to the above mentioned properties, the project simulates shadows and reflections in real time. Limitations of the current implementation, that cannot be seen in a [provided demo](https://netglade.github.io/flutter_3d_ui), are discussed in this [blog post (todo: url)](https://www.netglade.cz/en/blog/bringing-mcps-to-the-cloud-how-we-won-the-e2b-hackathon).

With further development, this project could evolve into a fully-featured library 🙏🤞.


## How It Works

Our implementation uses ray tracing and physically based rendering in Flutter's fragment shader. The shader receives the positions, dimensions, and parameters of all `SpatialContainers`, as well as the underlying UI as a texture, to create realistic 3D effects. More detailed technical description is in the [blog post](https://www.netglade.cz/en/blog/bringing-mcps-to-the-cloud-how-we-won-the-e2b-hackathon).


## Local Setup

Make sure you have [FVM installed](https://fvm.app/documentation/getting-started/installation).

```bash
fvm install
fvm flutter pub get
fvm flutter run
```
