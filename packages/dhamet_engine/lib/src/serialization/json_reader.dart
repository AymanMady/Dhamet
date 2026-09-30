/// Defensive readers for JSON-decoded data.
///
/// Saved games may be truncated, edited by hand or written by another
/// version of the app: every problem is reported as a [FormatException]
/// naming the offending field instead of a type error.
library;

/// A decoded JSON object.
typedef JsonMap = Map<String, Object?>;

/// [value] as a JSON object.
JsonMap readMap(Object? value, String field) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$field: expected a JSON object', value);
}

/// [value] as a JSON array.
List<Object?> readList(Object? value, String field) {
  if (value is List<Object?>) return value;
  throw FormatException('$field: expected a JSON array', value);
}

/// The required value of [key], of type [T].
T readField<T>(JsonMap json, String key, String context) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('$context.$key: expected a value of type $T', value);
}

/// The value of [key] of type [T], or [defaultValue] when the key is absent
/// or null. Lets older saves load after new settings are added.
T readOptional<T extends Object>(
  JsonMap json,
  String key,
  String context,
  T defaultValue,
) {
  final value = json[key];
  if (value == null) return defaultValue;
  if (value is T) return value;
  throw FormatException('$context.$key: expected a value of type $T', value);
}

/// The value of [E] named [value].
E readEnum<E extends Enum>(List<E> values, Object? value, String field) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException(
    '$field: expected one of ${values.map((v) => v.name).join(', ')}',
    value,
  );
}
