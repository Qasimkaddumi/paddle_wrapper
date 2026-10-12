import 'package:flutter/material.dart';

import 'features/confirmation/order_backend.dart';
import 'features/home/home_page.dart';

/// Root widget: Material 3 theme and the home page listing the demos.
class ExampleApp extends StatelessWidget {
  /// Creates the app. [backend] stands in for your own order API.
  const ExampleApp({required this.backend, super.key});

  /// Your backend, used by the confirmation page to poll order status.
  final OrderBackend backend;

  static const Color _seed = Color(0xFF3D5AFE);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'paddle_wrapper example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
    ),
    home: HomePage(backend: backend),
  );
}
