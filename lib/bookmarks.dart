import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/csv_config.dart';

const defaultCategories = [
  'Articles',
  'Application',
  'Blog',
  'Business',
  'Drawing',
  'Entertainment',
  'Food',
  'Game',
  'Health',
  'Kids',
  'Movies',
  'Motivational',
  'Music',
  'News',
  'Others',
  'Study',
  'Stocks',
  'Sports',
  'Technology',
  'Video',
  'Youtube',
];

enum LinkSort { newest, oldest, az, za }

String normalizeUrl(String input) {
  var text = input.trim();
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.host.startsWith('.') ||
      uri.userInfo.isNotEmpty ||
      RegExp(r'\s').hasMatch(text)) {
    throw const FormatException('Informe uma URL HTTP ou HTTPS válida.');
  }
  return uri.toString();
}

String? extractSharedUrl(String text) {
  final match = RegExp(
    r'https?://[^\s<>"\x27]+',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  try {
    return normalizeUrl(match.group(0)!);
  } on FormatException {
    return null;
  }
}

@immutable
class Bookmark {
  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.createdAt,
    this.favorite = false,
    this.image = '',
  });

  final String id, title, url, category, image;
  final DateTime createdAt;
  final bool favorite;

  Bookmark copyWith({
    String? title,
    String? url,
    String? category,
    bool? favorite,
  }) => Bookmark(
    id: id,
    title: title ?? this.title,
    url: url ?? this.url,
    category: category ?? this.category,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
    image: image,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'favorite': favorite,
    'image': image,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'] as String,
    title: json['title'] as String,
    url: normalizeUrl(json['url'] as String),
    category: json['category'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    favorite: json['favorite'] as bool,
    image: json['image'] as String? ?? '',
  );
}

@immutable
class LibraryState {
  LibraryState({
    Iterable<Bookmark> links = const [],
    Iterable<String> categories = defaultCategories,
    ThemeMode? themeMode,
    bool? dark,
    this.onboarded = false,
    this.sort = LinkSort.newest,
  }) : links = List.unmodifiable(links),
       categories = List.unmodifiable(categories),
       themeMode =
           themeMode ??
           (dark != null
               ? (dark ? ThemeMode.dark : ThemeMode.light)
               : ThemeMode.system);

  final List<Bookmark> links;
  final List<String> categories;
  final ThemeMode themeMode;
  final bool onboarded;
  final LinkSort sort;

  bool get dark => themeMode == ThemeMode.dark;

  LibraryState copyWith({
    Iterable<Bookmark>? links,
    Iterable<String>? categories,
    ThemeMode? themeMode,
    bool? dark,
    bool? onboarded,
    LinkSort? sort,
  }) {
    final resolvedThemeMode =
        themeMode ??
        (dark != null
            ? (dark ? ThemeMode.dark : ThemeMode.light)
            : this.themeMode);
    return LibraryState(
      links: links ?? this.links,
      categories: categories ?? this.categories,
      themeMode: resolvedThemeMode,
      onboarded: onboarded ?? this.onboarded,
      sort: sort ?? this.sort,
    );
  }

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'links': links.map((e) => e.toJson()).toList(),
    'categories': categories,
    'themeMode': themeMode.name,
    'dark': dark,
    'onboarded': onboarded,
    'sort': sort.name,
  };

  factory LibraryState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Versão de armazenamento não suportada.');
    }
    final links = (json['links'] as List)
        .map((e) => Bookmark.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final categories = (json['categories'] as List).cast<String>();
    if (links.map((e) => e.id).toSet().length != links.length ||
        categories.toSet().length != categories.length ||
        categories.any((e) => e.trim().isEmpty) ||
        links.any((e) => !categories.contains(e.category))) {
      throw const FormatException('Armazenamento inconsistente.');
    }

    ThemeMode resolvedThemeMode;
    if (json['themeMode'] is String) {
      resolvedThemeMode = ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      );
    } else if (json['dark'] is bool) {
      resolvedThemeMode = (json['dark'] as bool)
          ? ThemeMode.dark
          : ThemeMode.light;
    } else {
      resolvedThemeMode = ThemeMode.system;
    }

    return LibraryState(
      links: links,
      categories: categories,
      themeMode: resolvedThemeMode,
      onboarded: json['onboarded'] as bool,
      sort: LinkSort.values.byName(json['sort'] as String),
    );
  }
}

abstract interface class LibraryStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferenceStorage implements LibraryStorage {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'my_link.library.v1';
  @override
  Future<String?> read() => _preferences.getString(_key);
  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}

String _formatNumber(int value) {
  final s = value.toString();
  return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
}

/// Mutations are serialized and only published after persistence succeeds.
/// This keeps concurrent favorites/imports from overwriting each other's state.
class BookmarkLibrary extends ChangeNotifier {
  BookmarkLibrary(
    this.storage, {
    this.csvConfig = const CsvConfig.fromEnvironment(),
  });
  final LibraryStorage storage;
  final CsvConfig csvConfig;
  LibraryState _state = LibraryState();
  LibraryState get state => _state;
  Future<void> _tail = Future.value();
  int _sequence = 0;

  Future<void> load() async {
    final saved = await storage.read();
    if (saved != null) {
      _state = LibraryState.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> _change(LibraryState Function(LibraryState) change) {
    final next = _tail.then((_) async {
      final state = change(_state);
      await storage.write(jsonEncode(state.toJson()));
      _state = state;
      notifyListeners();
    });
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> save({
    String? id,
    required String title,
    required String url,
    required String category,
  }) {
    final normalized = normalizeUrl(url);
    return _change((s) {
      if (!s.categories.contains(category)) {
        throw const FormatException('Selecione uma categoria existente.');
      }
      final index = s.links.indexWhere((e) => e.id == id);
      if (id != null && index < 0) {
        throw const FormatException('O link não existe mais.');
      }
      final name = title.trim().isEmpty
          ? Uri.parse(normalized).host
          : title.trim();
      final link = index < 0
          ? Bookmark(
              id: _id(),
              title: name,
              url: normalized,
              category: category,
              createdAt: DateTime.now(),
            )
          : s.links[index].copyWith(
              title: name,
              url: normalized,
              category: category,
            );
      return s.copyWith(
        links: [
          for (final old in s.links)
            if (old.id != id) old,
          link,
        ],
      );
    });
  }

  Future<void> delete(String id) =>
      _change((s) => s.copyWith(links: s.links.where((e) => e.id != id)));

  Future<void> toggleFavorite(String id) => _change(
    (s) => s.copyWith(
      links: s.links.map(
        (e) => e.id == id ? e.copyWith(favorite: !e.favorite) : e,
      ),
    ),
  );

  Future<void> addCategory(String name) => _change((s) {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 80) {
      throw const FormatException('Use um nome de 1 a 80 caracteres.');
    }
    if (s.categories.any((e) => e.toLowerCase() == clean.toLowerCase())) {
      throw const FormatException('A categoria já existe.');
    }
    return s.copyWith(categories: [...s.categories, clean]);
  });

  // The original has explicit deletion queries for category and its links.
  // This reconstruction asks for confirmation before applying both together.
  Future<void> deleteCategory(String name) => _change(
    (s) => s.copyWith(
      categories: s.categories.where((e) => e != name),
      links: s.links.where((e) => e.category != name),
    ),
  );

  Future<void> setThemeMode(ThemeMode mode) =>
      _change((s) => s.copyWith(themeMode: mode));
  Future<void> setDark(bool value) =>
      setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  Future<void> setSort(LinkSort value) =>
      _change((s) => s.copyWith(sort: value));
  Future<void> finishOnboarding() =>
      _change((s) => s.copyWith(onboarded: true));

  List<Bookmark> query({
    String text = '',
    String? category,
    bool favorites = false,
    bool timeline = false,
  }) {
    final needle = text.trim().toLowerCase();
    final result = _state.links
        .where(
          (e) =>
              (category == null || e.category == category) &&
              (!favorites || e.favorite) &&
              [
                e.title,
                e.url,
                e.category,
              ].any((v) => v.toLowerCase().contains(needle)),
        )
        .toList();
    result.sort((a, b) {
      final order = timeline ? LinkSort.newest : _state.sort;
      final int compared = switch (order) {
        LinkSort.newest => b.createdAt.compareTo(a.createdAt),
        LinkSort.oldest => a.createdAt.compareTo(b.createdAt),
        LinkSort.az => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        LinkSort.za => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      };
      return compared == 0 ? a.id.compareTo(b.id) : compared;
    });
    return result;
  }

  static const csvHeader = [
    'LinkName',
    'Link',
    'Category',
    'CategoryImage',
    'UrlImage',
    'IsFavorite',
  ];

  String exportCsv() => const ListToCsvConverter().convert([
    csvHeader,
    for (final link in _state.links)
      [
        link.title,
        link.url,
        link.category,
        0,
        link.image,
        link.favorite ? 'TRUE' : 'FALSE',
      ],
  ]);

  Future<void> importCsv(String source) async {
    if (utf8.encode(source).length > csvConfig.maxCsvSizeBytes) {
      throw FormatException(
        'O CSV deve ter no máximo ${csvConfig.maxCsvSizeMb} MB.',
      );
    }
    final clean = source.replaceFirst(RegExp(r'^\uFEFF'), '');
    final eol = clean.contains('\r\n') ? '\r\n' : '\n';
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(clean, eol: eol);
    if (rows.isEmpty ||
        !listEquals(rows.first, csvHeader) ||
        rows.length > csvConfig.maxImportLinks + 1) {
      throw FormatException(
        'CSV inválido: confira o cabeçalho e o limite de ${_formatNumber(csvConfig.maxImportLinks)} links.',
      );
    }
    // Validate the entire file before the single commit: no partial imports.
    final imported = <Bookmark>[];
    final now = DateTime.now();
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length != 6) {
        throw FormatException('Linha ${i + 1}: esperadas 6 colunas.');
      }
      final cells = row.map((e) => e.toString()).toList();
      final favorite = cells[5].trim().toLowerCase();
      if (!['true', 'false', '1', '0'].contains(favorite)) {
        throw FormatException('Linha ${i + 1}: favorito inválido.');
      }
      final category = cells[2].trim().isEmpty ? 'Others' : cells[2].trim();
      if (category.length > 80) {
        throw FormatException('Linha ${i + 1}: categoria longa demais.');
      }
      final url = normalizeUrl(cells[1]);
      imported.add(
        Bookmark(
          id: _id(),
          title: cells[0].trim().isEmpty
              ? Uri.parse(url).host
              : cells[0].trim(),
          url: url,
          category: category,
          createdAt: now,
          favorite: ['true', '1'].contains(favorite),
          image: cells[4],
        ),
      );
    }
    await _change(
      (s) => s.copyWith(
        links: [...s.links, ...imported],
        categories: {...s.categories, ...imported.map((e) => e.category)},
      ),
    );
  }
}
