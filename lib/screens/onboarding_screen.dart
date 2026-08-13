import 'package:flutter/material.dart';

import 'home_screen.dart';

enum BushelRole { volunteer, coordinator }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  BushelRole _role = BushelRole.volunteer;
  bool _familyMode = false;
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showProfileSetup() => setState(() => _step = 1);

  void _completeOnboarding() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _step = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_step) {
            0 => _WelcomeStep(onContinue: _showProfileSetup),
            1 => _ProfileStep(
              formKey: _formKey,
              nameController: _nameController,
              role: _role,
              familyMode: _familyMode,
              onRoleChanged: (role) => setState(() => _role = role),
              onFamilyModeChanged: (value) =>
                  setState(() => _familyMode = value),
              onBack: () => setState(() => _step = 0),
              onContinue: _completeOnboarding,
            ),
            _ => HomeScreen(name: _nameController.text.trim()),
          },
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headlineSize = width < 480 ? 46.0 : 64.0;

    return SingleChildScrollView(
      key: const ValueKey('welcome'),
      padding: EdgeInsets.fromLTRB(
        width < 600 ? 24 : 48,
        width < 600 ? 36 : 72,
        width < 600 ? 24 : 48,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xFF31C663),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3331C663),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF083F24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      color: Color(0xFF5CE88B),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'The community food bank network',
                        style: TextStyle(
                          color: Color(0xFF5CE88B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'One app for\n'),
                    TextSpan(
                      text: 'every food bank.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: headlineSize,
                  height: 1.03,
                  letterSpacing: -2.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Bushel brings '),
                    TextSpan(
                      text: 'every local food bank into one map',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ', fills volunteer shifts with '),
                    TextSpan(
                      text: 'real-time calendars',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text:
                          ', assigns the work on-site, and turns giving into a ',
                    ),
                    TextSpan(
                      text: 'game families and kids love',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' — all in one platform.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF46564D),
                  fontSize: 20,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get started'),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No account required · Takes less than 2 minutes',
                style: TextStyle(color: Color(0xFF728078)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.formKey,
    required this.nameController,
    required this.role,
    required this.familyMode,
    required this.onRoleChanged,
    required this.onFamilyModeChanged,
    required this.onBack,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final BushelRole role;
  final bool familyMode;
  final ValueChanged<BushelRole> onRoleChanged;
  final ValueChanged<bool> onFamilyModeChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Welcome to Bushel',
                  style: TextStyle(
                    fontSize: 40,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tell us a little about yourself so we can shape your experience.',
                  style: TextStyle(
                    color: Color(0xFF5E6D64),
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'What should we call you?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Your first name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name to continue'
                      : null,
                ),
                const SizedBox(height: 28),
                const Text(
                  'How will you use Bushel?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SegmentedButton<BushelRole>(
                  segments: const [
                    ButtonSegment(
                      value: BushelRole.volunteer,
                      icon: Icon(Icons.volunteer_activism_outlined),
                      label: Text('Volunteer'),
                    ),
                    ButtonSegment(
                      value: BushelRole.coordinator,
                      icon: Icon(Icons.groups_outlined),
                      label: Text('Coordinator'),
                    ),
                  ],
                  selected: {role},
                  onSelectionChanged: (selection) =>
                      onRoleChanged(selection.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(vertical: 3),
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: const Color(0xFFF1F8F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFD8EBDD)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.all(18),
                    value: familyMode,
                    onChanged: onFamilyModeChanged,
                    secondary: const Icon(Icons.family_restroom),
                    title: const Text(
                      'I’m volunteering with family',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Unlock family challenges and an optional Kid Mode.',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: onContinue,
                  child: const Text('Finish setup'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your choices stay on this device for now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF728078)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
