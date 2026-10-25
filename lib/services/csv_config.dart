// ignore_for_file: prefer_initializing_formals

/// Configuration for CSV export and import limits, configurable via .env.
class CsvConfig {
  const CsvConfig({
    int maxCsvSizeMb = defaultMaxCsvSizeMb,
    int maxImportLinks = defaultMaxImportLinks,
  }) : _maxCsvSizeMb = maxCsvSizeMb,
       _maxImportLinks = maxImportLinks;

  const CsvConfig.fromEnvironment()
    : _maxCsvSizeMb = const int.fromEnvironment(
        'MAX_CSV_SIZE_MB',
        defaultValue: defaultMaxCsvSizeMb,
      ),
      _maxImportLinks = const int.fromEnvironment(
        'MAX_CSV_IMPORT_LINKS',
        defaultValue: defaultMaxImportLinks,
      );

  static const int defaultMaxCsvSizeMb = 5;
  static const int defaultMaxImportLinks = 10000;

  final int _maxCsvSizeMb;
  final int _maxImportLinks;

  int get maxCsvSizeMb =>
      _maxCsvSizeMb > 0 ? _maxCsvSizeMb : defaultMaxCsvSizeMb;

  int get maxCsvSizeBytes => maxCsvSizeMb * 1024 * 1024;

  int get maxImportLinks =>
      _maxImportLinks > 0 ? _maxImportLinks : defaultMaxImportLinks;
}
