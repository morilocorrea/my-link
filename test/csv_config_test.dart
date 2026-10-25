import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/services/csv_config.dart';

void main() {
  group('CsvConfig', () {
    test('default constructor uses standard 5 MB and 10000 links', () {
      const config = CsvConfig();
      expect(config.maxCsvSizeMb, CsvConfig.defaultMaxCsvSizeMb);
      expect(config.maxCsvSizeBytes, 5 * 1024 * 1024);
      expect(config.maxImportLinks, CsvConfig.defaultMaxImportLinks);
    });

    test('non-positive numbers fall back to safe defaults', () {
      const config = CsvConfig(maxCsvSizeMb: -1, maxImportLinks: 0);
      expect(config.maxCsvSizeMb, CsvConfig.defaultMaxCsvSizeMb);
      expect(config.maxCsvSizeBytes, 5 * 1024 * 1024);
      expect(config.maxImportLinks, CsvConfig.defaultMaxImportLinks);
    });

    test('custom values are respected correctly', () {
      const config = CsvConfig(maxCsvSizeMb: 10, maxImportLinks: 50000);
      expect(config.maxCsvSizeMb, 10);
      expect(config.maxCsvSizeBytes, 10 * 1024 * 1024);
      expect(config.maxImportLinks, 50000);
    });

    test('fromEnvironment reads values or safe fallbacks', () {
      const config = CsvConfig.fromEnvironment();
      expect(config.maxCsvSizeMb, greaterThan(0));
      expect(config.maxCsvSizeBytes, greaterThan(0));
      expect(config.maxImportLinks, greaterThan(0));
    });
  });
}
