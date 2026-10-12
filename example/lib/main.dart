import 'package:flutter/material.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'features/confirmation/order_backend.dart';
import 'features/setup/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StartupScreen(
          title: 'Almost there',
          message:
              'Pass the missing values with --dart-define and restart the app.',
          details: [for (final name in AppConfig.missing) 'Missing: $name'],
        ),
      ),
    );
    return;
  }

  try {
    await Paddle.initialize(
      PaddleConfig(
        clientToken: AppConfig.clientToken,
        checkoutSettings: const CheckoutSettings(
          theme: CheckoutTheme.light,
          locale: CheckoutLocale.en,
        ),
      ),
    );
  } on PaddleException catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StartupScreen(
          title: 'Paddle could not start',
          message: error.message,
          details: [error.runtimeType.toString()],
        ),
      ),
    );
    return;
  }

  runApp(ExampleApp(backend: FakeOrderBackend()));
}
