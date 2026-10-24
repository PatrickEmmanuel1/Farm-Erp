typedef JsonRow = Map<String, dynamic>;

String? stringValue(JsonRow row, String key) => row[key]?.toString();

double? doubleValue(JsonRow row, String key) {
  final value = row[key];
  if (value is num) return value.toDouble();
  return value is String ? double.tryParse(value) : null;
}

int? intValue(JsonRow row, String key) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return value is String ? int.tryParse(value) : null;
}

bool boolValue(JsonRow row, String key, {bool fallback = false}) {
  final value = row[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return switch (value.toLowerCase()) {
      'true' || 't' || '1' => true,
      'false' || 'f' || '0' => false,
      _ => fallback,
    };
  }
  return fallback;
}
