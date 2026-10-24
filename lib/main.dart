import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'firebase_bootstrap.dart';
import 'demo_app.dart';
import 'demo_config.dart';

const demoMode = bool.fromEnvironment('BUSHEL_DEMO') && !mockQrMode;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(demoMode ? const DemoApp() : const FirebaseBootstrap());
}

class BushelApp extends StatelessWidget {
  const BushelApp({
    super.key,
    this.home = const OnboardingScreen(),
    this.builder,
  });

  final Widget home;
  final TransitionBuilder? builder;

  static const Color seedColor = Color(0xFF31C663);
  static const Color inkColor = Color(0xFF0C2A1B);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Bushel',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final content = builder?.call(context, child) ?? child!;
        if (!mockQrMode) return content;
        return Column(
          children: [
            const Material(
              color: Color(0xFFFFE9BD),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: Text('Mock QR · Firebase data is live')),
                ),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFCFDFB),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: inkColor,
          displayColor: inkColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE6DF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE6DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: inkColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: home,
    );
  }
}
