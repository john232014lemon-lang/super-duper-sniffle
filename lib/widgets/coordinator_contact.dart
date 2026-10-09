import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../models/contact_phone.dart';

class CoordinatorContact extends StatefulWidget {
  const CoordinatorContact({super.key, required this.uid});
  final String uid;
  @override
  State<CoordinatorContact> createState() => _CoordinatorContactState();
}

class _CoordinatorContactState extends State<CoordinatorContact> {
  CatalogStore? _store;
  Stream<String>? _phone;
  void _subscribe() =>
      _phone = _store?.repository.watchCoordinatorPhone(widget.uid);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = CatalogScope.maybeOf(context);
    if (!identical(store, _store)) {
      _store = store;
      _subscribe();
    }
  }

  @override
  void didUpdateWidget(CoordinatorContact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) _subscribe();
  }

  Future<void> _open(String scheme, String phone) async {
    try {
      if (await launchUrl(Uri(scheme: scheme, path: phone))) return;
    } catch (_) {
      /* The device may not have a phone or SMS app. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open ${scheme == 'tel' ? 'calling' : 'text messaging'}. Use $phone on your phone.',
        ),
      ),
    );
  }

  Widget _buttons(String value) {
    final phone = ContactPhone.normalize(value);
    if (phone.isEmpty || !ContactPhone.valid(phone)) {
      return const Text('Coordinator: no number provided');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText('Coordinator: $phone'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _open('tel', phone),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call coordinator'),
            ),
            OutlinedButton.icon(
              onPressed: () => _open('sms', phone),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Text coordinator'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_store == null) {
      return _buttons(
        widget.uid == 'parent' ? SessionStore.instance.contactPhone : '',
      );
    }
    return StreamBuilder<String>(
      stream: _phone,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(_subscribe),
            child: const Text('Contact unavailable. Retry'),
          );
        }
        if (!snapshot.hasData) {
          return const Text('Loading coordinator contact…');
        }
        return _buttons(snapshot.data!);
      },
    );
  }
}
