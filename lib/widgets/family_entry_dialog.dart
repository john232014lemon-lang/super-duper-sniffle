import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';

class FamilyEntryDialog extends StatefulWidget {
  const FamilyEntryDialog({
    super.key,
    required this.store,
    required this.childEntry,
  });
  final CatalogStore store;
  final bool childEntry;
  @override
  State<FamilyEntryDialog> createState() => _FamilyEntryDialogState();
}

class _FamilyEntryDialogState extends State<FamilyEntryDialog> {
  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();
  final _target = TextEditingController(text: '1');
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.repository.saveFamilyEntry(
        widget.store.uid,
        widget.childEntry ? 'children' : 'challenges',
        _text.text,
        targetShifts: widget.childEntry ? 1 : int.parse(_target.text.trim()),
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
      scrollable: true,
      title: Text(
        widget.childEntry ? 'Add a kid account' : 'Create a challenge',
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) Text(_error!),
            TextFormField(
              key: ValueKey(
                widget.childEntry ? 'kid-name-field' : 'challenge-field',
              ),
              controller: _text,
              enabled: !_saving,
              autofocus: true,
              maxLength: widget.childEntry ? 80 : 160,
              decoration: InputDecoration(
                labelText: widget.childEntry ? 'Kid’s name' : 'Challenge',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null,
            ),
            if (!widget.childEntry) ...[
              const Text(
                'Progress counts distinct coordinator-confirmed family shifts, including past shifts.',
              ),
              TextFormField(
                controller: _target,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Completed-shift goal',
                ),
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  return count == null || count < 1 || count > 100
                      ? 'Enter 1 to 100 shifts'
                      : null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(
            _saving
                ? 'Saving...'
                : widget.childEntry
                ? 'Create kid account'
                : 'Add challenge',
          ),
        ),
      ],
    ),
  );
}
