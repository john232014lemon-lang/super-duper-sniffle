class ContactPhone {
  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[\s().-]'), '');
  static bool valid(String value) =>
      value.isEmpty || RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value);
}
