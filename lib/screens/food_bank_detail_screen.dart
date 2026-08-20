import 'package:flutter/material.dart';

import '../data/mock_food_banks.dart';
import '../data/shift_store.dart';
import '../models/food_bank.dart';

class FoodBankDetailScreen extends StatefulWidget {
  const FoodBankDetailScreen({super.key, required this.foodBank});

  final FoodBank foodBank;

  @override
  State<FoodBankDetailScreen> createState() => _FoodBankDetailScreenState();
}

class _FoodBankDetailScreenState extends State<FoodBankDetailScreen> {
  late final List<FoodBankShift> _shifts = [...widget.foodBank.shifts];

  Future<void> _addShift() async {
    final shift = await showDialog<FoodBankShift>(
      context: context,
      builder: (_) => const _AddShiftDialog(),
    );
    if (shift == null) return;

    setState(() => _shifts.add(shift));
    ShiftStore.instance.addAvailable(widget.foodBank, shift);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${shift.title} was added.')));
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = mockFoodBanks
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
              _BankHero(foodBank: widget.foodBank),
              const SizedBox(height: 24),
              const Text(
                'About this food bank',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                widget.foodBank.description,
                style: const TextStyle(
                  color: Color(0xFF5F6D65),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: widget.foodBank.address,
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.schedule, text: widget.foodBank.hours),
              const SizedBox(height: 28),
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
                  FilledButton.icon(
                    onPressed: _addShift,
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
                      signedUp: ShiftStore.instance.isSignedUp(_shifts[index]),
                      onTap: () => _confirmSignup(_shifts[index]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
    ShiftStore.instance.signUp(widget.foodBank, shift);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shift added to My shifts.')));
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
          const Text(
            'Open now · Volunteers welcome',
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
  final VoidCallback onTap;

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
              onPressed: signedUp ? null : onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(signedUp ? 'Added' : 'Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddShiftDialog extends StatefulWidget {
  const _AddShiftDialog();

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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      FoodBankShift(
        title: _title.text.trim(),
        date: _date.text.trim(),
        time: _time.text.trim(),
        station: _station.text.trim(),
        spotsLeft: int.parse(_spots.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add your shift'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('shift-title'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Shift name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _date,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'Sat, Jun 27',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _time,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: '9:00–11:00 AM',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _station,
                  decoration: const InputDecoration(labelText: 'Station'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _spots,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Open spots'),
                  validator: (value) {
                    final spots = int.tryParse(value ?? '');
                    return spots == null || spots < 1
                        ? 'Enter at least 1 spot'
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add shift')),
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
          '${foodBank.distance} · ${foodBank.shifts.length} upcoming shifts',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
