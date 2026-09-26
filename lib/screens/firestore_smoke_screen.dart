import 'package:flutter/material.dart';

import '../services/firestore_smoke_test.dart';

class FirestoreSmokeScreen extends StatefulWidget {
  const FirestoreSmokeScreen({
    super.key,
    this.runCheck = runFirestoreSmokeTest,
  });
  final Future<void> Function() runCheck;

  @override
  State<FirestoreSmokeScreen> createState() => _FirestoreSmokeScreenState();
}

class _FirestoreSmokeScreenState extends State<FirestoreSmokeScreen> {
  bool _running = false;
  String _status = 'Ready to write, read, and delete one temporary document.';

  Future<void> _run() async {
    setState(() {
      _running = true;
      _status = 'Checking the database…';
    });
    try {
      await widget.runCheck();
      if (mounted) {
        setState(
          () => _status = 'Passed: write, server read, and deletion verified.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Check failed. Verify your connection, sign-in, and deployed rules. A temporary document may need cleanup if the connection was interrupted.',
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firestore connection check')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bushel · Dallas, Texas (us-south1)'),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(_status, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _running ? null : _run,
                child: Text(_running ? 'Checking…' : 'Run connection check'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
