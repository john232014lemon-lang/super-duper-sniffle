/// Firebase stays live; only the check-in code flow uses mock tokens.
const mockQrMode = bool.fromEnvironment('BUSHEL_MOCK');

/// Presentation accounts used only when [mockQrMode] is true.
const mockAccountEmailA = 'a@a.co';
const mockAccountEmailB = 'b@b.co';

/// Shared password for a@a.co / b@b.co. Pass at run time; never commit real values.
/// Example: `--dart-define=BUSHEL_MOCK_PASSWORD=your-password`
/// Optional per-account overrides: `BUSHEL_MOCK_PASSWORD_A` / `BUSHEL_MOCK_PASSWORD_B`.
const _mockPasswordShared = String.fromEnvironment('BUSHEL_MOCK_PASSWORD');
const _mockPasswordAOverride = String.fromEnvironment(
  'BUSHEL_MOCK_PASSWORD_A',
);
const _mockPasswordBOverride = String.fromEnvironment(
  'BUSHEL_MOCK_PASSWORD_B',
);

String get mockAccountPasswordA =>
    _mockPasswordAOverride.isNotEmpty ? _mockPasswordAOverride : _mockPasswordShared;
String get mockAccountPasswordB =>
    _mockPasswordBOverride.isNotEmpty ? _mockPasswordBOverride : _mockPasswordShared;

bool get mockAccountsConfigured =>
    mockAccountPasswordA.isNotEmpty && mockAccountPasswordB.isNotEmpty;

String mockPasswordForEmail(String email) {
  final normalized = email.trim().toLowerCase();
  if (normalized == mockAccountEmailA) return mockAccountPasswordA;
  if (normalized == mockAccountEmailB) return mockAccountPasswordB;
  return '';
}

String mockOtherAccountEmail(String? currentEmail) {
  final normalized = currentEmail?.trim().toLowerCase();
  return normalized == mockAccountEmailB
      ? mockAccountEmailA
      : mockAccountEmailB;
}

/// Prevents the signed-out auth screen from flashing while Profile switches a↔b.
class MockAccountSwitch {
  static bool inProgress = false;
}
