import 'package:flutter/material.dart';

import '../data/mock_food_banks.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';
import '../data/shift_store.dart';
import '../data/session_store.dart';
import '../models/food_bank.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/coordinator_application.dart';
import 'attendance_management_screen.dart';

class FoodBankDetailScreen extends StatefulWidget {
  const FoodBankDetailScreen({super.key, required this.foodBank});

  final FoodBank foodBank;

  @override
  State<FoodBankDetailScreen> createState() => _FoodBankDetailScreenState();
}

class _FoodBankDetailScreenState extends State<FoodBankDetailScreen> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    ShiftStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ShiftStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  FoodBank get _bank {
    final banks = CatalogScope.maybeOf(context)?.banks;
    return banks?.where((bank) => bank.id == widget.foodBank.id).firstOrNull ??
        widget.foodBank;
  }

  Future<void> _save(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(catalogError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<FoodBankShift> get _shifts => ShiftStore.instance.available
      .where(
        (listing) => widget.foodBank.id != null
            ? listing.foodBank.id == widget.foodBank.id
            : listing.foodBank == widget.foodBank,
      )
      .map((listing) => listing.shift)
      .toList();

  Future<void> _addShift() async {
    final bank = _bank;
    final catalog = CatalogScope.maybeOf(context);
    final shift = await showDialog<FoodBankShift>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddShiftDialog(
        onSave: (shift) async {
          if (!mounted) throw const CatalogException('This session has ended.');
          if (catalog != null) {
            await catalog.repository.createShift(catalog.uid, bank.id!, shift);
          } else {
            await ShiftStore.instance.addAvailable(bank, shift);
          }
        },
      ),
    );
    if (shift != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${shift.title} was added.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null && (catalog.banksLoading || catalog.banksFailed)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food bank details')),
        body: Center(child: CatalogStatus(store: catalog)),
      );
    }
    if (catalog != null &&
        !catalog.banks.any((bank) => bank.id == widget.foodBank.id)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food bank details')),
        body: const Center(
          child: Text('This food bank is no longer available.'),
        ),
      );
    }
    final recommendations = (catalog?.banks ?? mockFoodBanks)
        .where((bank) => bank.name != widget.foodBank.name)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Food bank details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _BankHero(foodBank: _bank),
              const SizedBox(height: 24),
              const Text(
                'About this food bank',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                _bank.description,
                style: const TextStyle(
                  color: Color(0xFF5F6D65),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.location_on_outlined, text: _bank.address),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.schedule, text: _bank.hours),
              const SizedBox(height: 28),
              if (catalog != null)
                CoordinatorApplication(store: catalog, bankId: _bank.id!),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Upcoming shifts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (catalog != null
                      ? !SessionStore.instance.isKidAccount &&
                            catalog.coordinatorBanks.contains(_bank.id)
                      : SessionStore.instance.role == BushelRole.coordinator)
                    FilledButton.icon(
                      onPressed: _busy ? null : _addShift,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add shift'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (catalog != null && catalog.accessFailed)
                TextButton(
                  onPressed: catalog.retry,
                  child: const Text('Retry coordinator access'),
                ),
              if (catalog != null &&
                  (catalog.shiftsLoading ||
                      catalog.shiftsFailed ||
                      _shifts.isEmpty))
                CatalogStatus(store: catalog, shifts: true)
              else
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    key: const ValueKey('shift-carousel'),
                    scrollDirection: Axis.horizontal,
                    itemCount: _shifts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 330,
                      child: _ShiftCard(
                        shift: _shifts[index],
                        signedUp: ShiftStore.instance.isSignedUp(
                          _shifts[index],
                        ),
                        onTap:
                            _busy ||
                                (catalog != null &&
                                    SessionStore.instance.isKidAccount)
                            ? null
                            : () => _confirmSignup(_shifts[index]),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (catalog != null && !SessionStore.instance.isKidAccount)
                for (final record in catalog.shifts.where(
                  (record) =>
                      record.bankId == _bank.id &&
                      record.creatorUid == catalog.uid,
                ))
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AttendanceManagementScreen(
                          shiftId: record.shift.id!,
                          title: record.shift.title,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text('Manage check-ins: ${record.shift.title}'),
                  ),
              const Text(
                'Recommended food banks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (bank) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecommendationCard(
                    foodBank: bank,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => FoodBankDetailScreen(foodBank: bank),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 1),
    );
  }

  Future<void> _confirmSignup(FoodBankShift shift) async {
    if (ShiftStore.instance.isSignedUp(shift)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm this shift?'),
        content: Text('${shift.title}\n${shift.date} · ${shift.time}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm signup'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await _save(
      () => ShiftStore.instance.signUp(_bank, shift),
      'Shift added to My shifts.',
    );
  }
}

class _BankHero extends StatelessWidget {
  const _BankHero({required this.foodBank});

  final FoodBank foodBank;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [foodBank.accent, const Color(0xFF123C2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(foodBank.icon, color: Colors.white, size: 48),
              const Spacer(),
              Chip(
                avatar: const Icon(Icons.near_me, size: 16),
                label: Text(foodBank.distance),
              ),
            ],
          ),
          const Spacer(),
          Text(
            foodBank.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            foodBank.id != null
                ? foodBank.hours
                : 'Open now · Volunteers welcome',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22B95C), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.shift,
    required this.signedUp,
    required this.onTap,
  });

  final FoodBankShift shift;
  final bool signedUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7EA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.calendar_month, color: Color(0xFF169B4B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shift.date} · ${shift.time}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${shift.station} · ${shift.spotsLeft} spots left',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: signedUp || shift.spotsLeft <= 0 ? null : onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                signedUp
                    ? 'Added'
                    : shift.spotsLeft <= 0
                    ? 'Full'
                    : 'Sign up',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddShiftDialog extends StatefulWidget {
  const _AddShiftDialog({required this.onSave});
  final Future<void> Function(FoodBankShift) onSave;

  @override
  State<_AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<_AddShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _station = TextEditingController();
  final _spots = TextEditingController(text: '1');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _time.dispose();
    _station.dispose();
    _spots.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = DateTime.tryParse(text);
    if (date == null ||
        date.year < 2000 ||
        date.year > 2100 ||
        date.toIso8601String().substring(0, 10) != text) {
      return null;
    }
    return date;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _parseDate(_date.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted) {
      _date.text = date.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final shift = FoodBankShift(
      title: _title.text.trim(),
      scheduledDate: _parseDate(_date.text)!,
      time: _time.text.trim(),
      station: _station.text.trim(),
      spotsLeft: int.parse(_spots.text),
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(shift);
      if (mounted) Navigator.of(context).pop(shift);
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_saving ? 'Saving shift...' : 'Add your shift'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                TextFormField(
                  enabled: !_saving,
                  key: const ValueKey('shift-title'),
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Shift name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: !_saving,
                  controller: _date,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      tooltip: 'Choose shift date',
                      onPressed: _saving ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month),
                    ),
                  ),
                  validator: (value) => _parseDate(value ?? '') == null
                      ? 'Enter a valid date (YYYY-MM-DD), 2000–2100'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: !_saving,
                  controller: _time,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: '9:00–11:00 AM',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: !_saving,
                  controller: _station,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Station'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: !_saving,
                  controller: _spots,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Open spots'),
                  validator: (value) {
                    final spots = int.tryParse(value ?? '');
                    return spots == null || spots < 1 || spots > 500
                        ? 'Enter 1 to 500 spots'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Add shift'),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.foodBank, required this.onTap});

  final FoodBank foodBank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: foodBank.accent.withValues(alpha: 0.15),
          child: Icon(foodBank.icon, color: foodBank.accent),
        ),
        title: Text(
          foodBank.shortName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${foodBank.distance} · ${ShiftStore.instance.available.where((listing) => foodBank.id != null ? listing.foodBank.id == foodBank.id : listing.foodBank == foodBank).length} upcoming shifts',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
