import '../demo_config.dart';
import '../models/check_in_token.dart';

/// Holds raw mock QR codes in this app session so the fake camera can show them.
/// Only active with BUSHEL_MOCK. Codes never go to Firestore.
class MockQrPresentationStore {
  MockQrPresentationStore._();
  static final instance = MockQrPresentationStore._();

  final Map<String, CheckInToken> _tokens = {};

  void remember(String shiftId, CheckInToken token) {
    if (!mockQrMode) return;
    _tokens[shiftId] = token;
  }

  CheckInToken? tokenFor(String shiftId, {DateTime? now}) {
    if (!mockQrMode) return null;
    final token = _tokens[shiftId];
    if (token == null) return null;
    final clock = now ?? DateTime.now();
    if (!clock.isBefore(token.expiresAt)) {
      _tokens.remove(shiftId);
      return null;
    }
    return token;
  }

  void clear() => _tokens.clear();
}
