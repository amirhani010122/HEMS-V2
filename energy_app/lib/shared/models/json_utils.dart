/// Shared, null-defensive JSON parsing helpers used by all plain-Dart models.
///
/// The backend emits snake_case keys; these helpers tolerate missing/null
/// values and multiple key spellings so the UI never crashes on a partial
/// or slightly different payload.

/// Returns the first non-null value among [keys] in [json].
dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

String asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

String? asStringOrNull(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

double asDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1' || s == 'online' || s == 'active') return true;
  if (s == 'false' || s == '0' || s == 'offline' || s == 'inactive') {
    return false;
  }
  return fallback;
}

/// Parses an ISO-8601 datetime, returning [DateTime.now] on failure.
DateTime asDate(dynamic v) {
  return asDateOrNull(v) ?? DateTime.now();
}

/// Parses an ISO-8601 datetime, returning null on failure.
DateTime? asDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

Map<String, dynamic>? asMapOrNull(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return null;
}
