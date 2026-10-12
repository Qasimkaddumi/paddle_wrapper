/// A decoded JSON object.
typedef JsonMap = Map<String, dynamic>;

/// Implemented by enums that map to a Paddle string value.
///
/// Paddle adds values over time, so every enum implementing this should
/// expose an `unknown` member used as a fallback when parsing.
mixin PaddleEnum on Enum {
  /// The value Paddle uses on the wire.
  String get value;
}

/// Parses [raw] into one of [values], returning [fallback] when it does not
/// match any known value.
T parsePaddleEnum<T extends PaddleEnum>(
  List<T> values,
  Object? raw, {
  required T fallback,
}) {
  for (final value in values) {
    if (value.value == raw) return value;
  }
  return fallback;
}

/// Like [parsePaddleEnum] but returns `null` when [raw] is `null`.
T? parsePaddleEnumOrNull<T extends PaddleEnum>(
  List<T> values,
  Object? raw, {
  required T fallback,
}) => raw == null ? null : parsePaddleEnum(values, raw, fallback: fallback);

/// Returns a copy of [json] without `null` values, so optional fields are
/// omitted rather than sent as `null` to Paddle.js.
JsonMap compactJson(Map<String, Object?> json) => {
  for (final entry in json.entries)
    if (entry.value != null) entry.key: entry.value,
};

/// Read helpers for loosely typed JSON coming back from Paddle.js.
extension JsonMapReader on JsonMap {
  /// Reads a string, or `null`. Numbers and bools are stringified; objects
  /// and lists are treated as malformed and yield `null`.
  String? stringOrNull(String key) => switch (this[key]) {
    final String value => value,
    final num value => value.toString(),
    final bool value => value.toString(),
    _ => null,
  };

  /// Reads a number, or `null`. Accepts numeric strings.
  num? numOrNull(String key) {
    final value = this[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Reads an int, or `null`. Accepts numeric strings.
  int? intOrNull(String key) => numOrNull(key)?.toInt();

  /// Reads a bool, or `null`.
  bool? boolOrNull(String key) {
    final value = this[key];
    return value is bool ? value : null;
  }

  /// Reads a nested object, or `null`.
  JsonMap? mapOrNull(String key) {
    final value = this[key];
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  /// Reads a list of objects, mapping each with [fromJson]. Missing or
  /// malformed lists yield an empty list.
  List<T> listOf<T>(String key, T Function(JsonMap json) fromJson) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) fromJson(item.cast<String, dynamic>()),
    ];
  }
}
