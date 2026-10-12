import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/platform/js_value_converter.dart';

void main() {
  group('normalizeJson', () {
    test('keeps JSON scalars and null unchanged', () {
      expect(normalizeJson(null), isNull);
      expect(normalizeJson('text'), 'text');
      expect(normalizeJson(true), isTrue);
      expect(normalizeJson(3), 3);
      expect(normalizeJson(1.5), 1.5);
    });

    test('converts maps to String-keyed maps recursively', () {
      final result = normalizeJson(<Object?, Object?>{
        'a': <Object?, Object?>{1: 'one', 'b': null},
      });

      expect(result, {
        'a': {'1': 'one', 'b': null},
      });
      expect(result, isA<Map<String, dynamic>>());
      expect(
        (result! as Map<String, dynamic>)['a'],
        isA<Map<String, dynamic>>(),
      );
    });

    test('converts iterables to lists recursively', () {
      final result = normalizeJson(<Object?>[
        1,
        <Object?, Object?>{'k': 'v'},
        <Object?>['nested'],
      ]);

      expect(result, [
        1,
        {'k': 'v'},
        ['nested'],
      ]);
    });

    test('falls back to toString for unknown objects', () {
      expect(normalizeJson(const _Opaque()), 'opaque!');
    });
  });

  group('toJsonMap', () {
    test('returns a String-keyed map for a map input', () {
      final result = toJsonMap(<Object?, Object?>{
        'data': <Object?, Object?>{'id': 'txn_1'},
      });

      expect(result, {
        'data': {'id': 'txn_1'},
      });
    });

    test('returns an empty map for null', () {
      expect(toJsonMap(null), isEmpty);
    });

    test('returns an empty map for non-map values', () {
      expect(toJsonMap(<Object?>[1, 2]), isEmpty);
      expect(toJsonMap('text'), isEmpty);
    });
  });
}

class _Opaque {
  const _Opaque();

  @override
  String toString() => 'opaque!';
}
