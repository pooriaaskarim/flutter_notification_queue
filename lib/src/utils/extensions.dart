extension ExtendedStringFuntionalities on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get downcase =>
      isEmpty ? this : '${this[0].toLowerCase()}${substring(1)}';
}
