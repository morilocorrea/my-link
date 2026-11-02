import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/main.dart';

void main() {
  group('resolveAppLocale unit tests', () {
    const supported = [Locale('en', 'US'), Locale('pt', 'BR')];

    test('exact pt-BR resolves to pt_BR', () {
      expect(
        resolveAppLocale(const Locale('pt', 'BR'), supported),
        const Locale('pt', 'BR'),
      );
      expect(
        resolveAppLocale(const Locale('PT', 'br'), supported),
        const Locale('pt', 'BR'),
      );
    });

    test('pt without region or pt-PT falls back to en_US', () {
      expect(
        resolveAppLocale(const Locale('pt'), supported),
        const Locale('en', 'US'),
      );
      expect(
        resolveAppLocale(const Locale('pt', 'PT'), supported),
        const Locale('en', 'US'),
      );
    });

    test('null device locale falls back to en_US', () {
      expect(
        resolveAppLocale(null, supported),
        const Locale('en', 'US'),
      );
    });

    test('other languages and regions fall back to en_US', () {
      for (final locale in [
        const Locale('en', 'US'),
        const Locale('en', 'GB'),
        const Locale('es', 'ES'),
        const Locale('fr', 'FR'),
        const Locale('de', 'DE'),
        const Locale('it', 'IT'),
        const Locale('ja', 'JP'),
        const Locale('zh', 'CN'),
      ]) {
        expect(
          resolveAppLocale(locale, supported),
          const Locale('en', 'US'),
          reason: 'Failed for ${locale.toString()}',
        );
      }
    });
  });
}
