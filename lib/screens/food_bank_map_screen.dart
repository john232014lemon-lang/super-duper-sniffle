import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';
import 'food_bank_detail_screen.dart';

class FoodBankMapScreen extends StatefulWidget {
  const FoodBankMapScreen({super.key});

  @override
  State<FoodBankMapScreen> createState() => _FoodBankMapScreenState();
}

class _FoodBankMapScreenState extends State<FoodBankMapScreen> {
  static const _houstonCenter = LatLng(29.7604, -95.3698);

  FoodBank? _selectedBank;

  void _selectBank(FoodBank bank) => setState(() => _selectedBank = bank);

  void _openDetails(FoodBank bank) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodBankDetailScreen(foodBank: bank),
      ),
    );
  }

  void _showLocationComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Find my location is coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Food banks nearby'),
            Text(
              'Houston, TX',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _houstonCenter,
                  initialZoom: 13.5,
                  minZoom: 3,
                  maxZoom: 18,
                  onTap: (_, _) => setState(() => _selectedBank = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bushel.bushel',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final bank in mockFoodBanks)
                        Marker(
                          point: bank.location,
                          width: 64,
                          height: 64,
                          child: _MapPin(
                            foodBank: bank,
                            selected: identical(_selectedBank, bank),
                            onTap: () => _selectBank(bank),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(18),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Color(0xFF718078)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Explore 3 Houston food banks',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 82,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'find-location',
                  tooltip: 'Find my location',
                  onPressed: _showLocationComingSoon,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF126D3A),
                  child: const Icon(Icons.my_location),
                ),
              ),
              if (_selectedBank != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 18,
                  child: _BankPreview(
                    foodBank: _selectedBank!,
                    onTap: () => _openDetails(_selectedBank!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.foodBank,
    required this.selected,
    required this.onTap,
  });

  final FoodBank foodBank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${foodBank.shortName} map marker',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1.12 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: foodBank.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(foodBank.icon, color: Colors.white, size: 27),
          ),
        ),
      ),
    );
  }
}

class _BankPreview extends StatelessWidget {
  const _BankPreview({required this.foodBank, required this.onTap});

  final FoodBank foodBank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
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
        trailing: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Text('View'),
        ),
      ),
    );
  }
}
