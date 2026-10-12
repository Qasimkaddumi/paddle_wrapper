import '../json.dart';

/// Converts a value produced by `dartify()` (or any loosely typed object)
/// into plain JSON-compatible Dart values.
///
/// Maps become `Map<String, dynamic>` with `toString()` keys, iterables
/// become `List<dynamic>`, and numbers, strings, bools and `null` are kept
/// as they are. Anything else falls back to its `toString()`.
///
/// This file has no JS imports so it can be unit tested on the Dart VM.
Object? normalizeJson(Object? value) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): normalizeJson(entry.value),
    };
  }
  if (value is Iterable) {
    return [for (final item in value) normalizeJson(item)];
  }
  return value.toString();
}

/// Converts [value] into a [JsonMap] via [normalizeJson].
///
/// Returns an empty map when [value] is `null` or is not a map, so callers
/// can always read fields without null checks.
JsonMap toJsonMap(Object? value) {
  final normalized = normalizeJson(value);
  return normalized is Map<String, dynamic> ? normalized : <String, dynamic>{};
}
