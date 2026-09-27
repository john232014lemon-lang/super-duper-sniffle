import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../services/catalog_repository.dart';

class CoordinatorApplication extends StatelessWidget {
  const CoordinatorApplication({
    super.key,
    required this.store,
    required this.bankId,
  });
  final CatalogStore store;
  final String bankId;
  @override
  Widget build(BuildContext context) {
    if (SessionStore.instance.isKidAccount) return const SizedBox.shrink();
    if (store.applicationsLoading) return const LinearProgressIndicator();
    if (store.applicationsFailed) {
      return TextButton(
        onPressed: store.retry,
        child: const Text('Retry coordinator application status'),
      );
    }
    final status = store.applications[bankId];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coordinate at this bank',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(switch (status) {
              'approved' => 'Your coordinator application is approved.',
              'pending' =>
                'Application submitted. Waiting for administrator approval.',
              'rejected' =>
                'Your application was not approved. Contact the bank for more information.',
              _ =>
                'Apply to help organize shifts. An administrator must approve your application.',
            }),
            if (status == null)
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      _ApplicationDialog(store: store, bankId: bankId),
                ),
                child: const Text('Apply to coordinate'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationDialog extends StatefulWidget {
  const _ApplicationDialog({required this.store, required this.bankId});
  final CatalogStore store;
  final String bankId;
  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: SessionStore.instance.parentName);
  final _contact = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.repository.applyToCoordinate(
        widget.store.uid,
        widget.bankId,
        _name.text,
        _contact.text,
        _reason.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = catalogError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Coordinator application'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) Text(_error!),
                for (final entry in [
                  (_name, 'Your name', 80),
                  (_contact, 'Email or phone', 160),
                  (_reason, 'Experience and why you want to coordinate', 2000),
                ])
                  TextFormField(
                    controller: entry.$1,
                    enabled: !_saving,
                    maxLength: entry.$3,
                    minLines: 1,
                    maxLines: entry.$3 == 2000 ? 5 : 1,
                    decoration: InputDecoration(labelText: entry.$2),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'This field is required'
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Submitting...' : 'Submit application'),
        ),
      ],
    ),
  );
}
