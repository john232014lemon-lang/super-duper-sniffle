import 'package:flutter/material.dart';

import 'data/coordinator_store.dart';
import 'data/session_store.dart';
import 'data/shift_store.dart';
import 'main.dart';

/// Explicit local development entry point. Never initializes Firebase.
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _clearData();
  }

  void _clearData() {
    SessionStore.instance.reset();
    CoordinatorStore.instance.reset();
    ShiftStore.instance.reset();
  }

  void _reset() {
    _clearData();
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) => BushelApp(
    key: ValueKey(_generation),
    builder: (context, child) => Column(
      children: [
        Material(
          color: const Color(0xFFE2F6E8),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Local demo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset demo'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child!),
      ],
    ),
  );
}
