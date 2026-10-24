import 'dart:convert';

import 'package:mylink/bookmarks.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStorage implements LibraryStorage {
  MemoryStorage({this.simulateLatency = true});
  final bool simulateLatency;
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (simulateLatency) await Future<void>.delayed(Duration.zero);
    if (fail) throw StateError('Disk full');
    this.value = value;
  }
}

void main() {
  late MemoryStorage storage;
  late BookmarkLibrary library;
  setUp(() {
    storage = MemoryStorage();
    library = BookmarkLibrary(storage);
  });
  tearDown(() => library.dispose());

  test(
    'HTTP validation and URL intake reject executable and credential URLs',
    () {
      expect(normalizeUrl(' example.com/path '), 'https://example.com/path');
      for (final value in [
        '',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'https://user:password@example.com',
        'https://a b.com',
        'ftp://a.com',
      ]) {
        expect(() => normalizeUrl(value), throwsFormatException, reason: value);
      }
      expect(
        extractSharedUrl('Confira https://example.com/a e salve'),
        'https://example.com/a',
      );
      expect(extractSharedUrl('sem link'), isNull);
    },
  );

  test('starts with 21 observed categories and no invented bookmarks', () {
    expect(library.state.categories.length, 21);
    expect(library.state.links, isEmpty);
  });

  test(
    'CRUD persists and reloads stable identity, time and favorite',
    () async {
      await library.save(
        title: 'Example',
        url: 'example.com',
        category: 'Study',
      );
      final initial = library.state.links.single;
      await library.toggleFavorite(initial.id);
      await library.save(
        id: initial.id,
        title: 'Edited',
        url: 'https://example.org',
        category: 'News',
      );
      final reloaded = BookmarkLibrary(storage);
      await reloaded.load();
      final link = reloaded.state.links.single;
      expect(link.id, initial.id);
      expect(link.createdAt, initial.createdAt);
      expect(link.favorite, isTrue);
      expect(link.title, 'Edited');
      expect(link.category, 'News');
      reloaded.dispose();
      await library.delete(initial.id);
      expect(library.state.links, isEmpty);
    },
  );

  test('serialized concurrent mutations never lose changes', () async {
    await Future.wait([
      library.save(title: 'A', url: 'a.com', category: 'Study'),
      library.save(title: 'B', url: 'b.com', category: 'News'),
      library.addCategory('Personal'),
    ]);
    expect(library.state.links.length, 2);
    final id = library.state.links.first.id;
    await Future.wait([library.toggleFavorite(id), library.toggleFavorite(id)]);
    expect(library.state.links.first.favorite, isFalse);
    expect(library.state.categories, contains('Personal'));
  });

  test('failed persistence keeps previous state and queue recovers', () async {
    storage.fail = true;
    await expectLater(library.addCategory('Personal'), throwsStateError);
    expect(library.state.categories, isNot(contains('Personal')));
    storage.fail = false;
    await library.addCategory('Personal');
    expect(library.state.categories, contains('Personal'));
  });

  test('category validation and confirmed cascade contract', () async {
    await expectLater(library.addCategory('study'), throwsFormatException);
    await expectLater(library.addCategory('  '), throwsFormatException);
    await expectLater(
      library.save(title: 'A', url: 'a.com', category: 'Missing'),
      throwsFormatException,
    );
    await library.save(title: 'A', url: 'a.com', category: 'Study');
    await library.save(title: 'B', url: 'b.com', category: 'News');
    await library.deleteCategory('Study');
    expect(library.state.links.single.category, 'News');
    expect(library.state.categories, isNot(contains('Study')));
  });

  test('search, categories, favorites and all four sorting modes', () async {
    // Windows clock resolution can give back-to-back saves equal timestamps.
    // Use persisted fixtures so chronological assertions do not depend on timing.
    storage.value = jsonEncode(
      LibraryState(
        links: [
          Bookmark(
            id: 'older',
            title: 'Zebra',
            url: 'https://z.com',
            category: 'Study',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          Bookmark(
            id: 'newer',
            title: 'Alpha',
            url: 'https://a.com',
            category: 'News',
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        ],
      ).toJson(),
    );
    await library.load();
    expect(library.query().first.title, 'Alpha');
    await library.setSort(LinkSort.oldest);
    expect(library.query().first.title, 'Zebra');
    await library.setSort(LinkSort.az);
    expect(library.query().first.title, 'Alpha');
    await library.setSort(LinkSort.za);
    expect(library.query().first.title, 'Zebra');
    expect(library.query(text: 'NEWS').single.title, 'Alpha');
    expect(library.query(category: 'Study').single.title, 'Zebra');
    await library.toggleFavorite(library.state.links.first.id);
    expect(library.query(favorites: true).single.title, 'Zebra');
    expect(library.query(timeline: true).first.title, 'Alpha');
  });

  test(
    'CSV round trip preserves quoted commas, quotes, newlines and Unicode',
    () async {
      const title = 'Olá, "mundo"\nSegunda linha';
      await library.save(
        title: title,
        url: 'https://a.com?q=x,y',
        category: 'Study',
      );
      await library.toggleFavorite(library.state.links.single.id);
      final destination = BookmarkLibrary(MemoryStorage());
      await destination.importCsv('\uFEFF${library.exportCsv()}');
      expect(destination.state.links.single.title, title);
      expect(destination.state.links.single.favorite, isTrue);
      expect(destination.state.links.single.url, 'https://a.com?q=x,y');
      destination.dispose();
    },
  );

  test(
    'legacy LF CSV imports categories, does not treat resource IDs as icons',
    () async {
      await library.importCsv(
        'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n'
        'My Link,https://example.com,Personal,2131231000,,true',
      );
      expect(library.state.categories, contains('Personal'));
      expect(library.state.links.single.favorite, isTrue);
    },
  );

  test('invalid CSV is atomic and preserves existing data', () async {
    await library.save(title: 'A', url: 'a.com', category: 'Study');
    final before = storage.value;
    await expectLater(
      library.importCsv(
        'LinkName,Link,Category,CategoryImage,UrlImage,IsFavorite\n'
        'Valid,https://example.com,Test,0,,TRUE\nInvalid,file:///test,Test,0,,FALSE',
      ),
      throwsFormatException,
    );
    expect(storage.value, before);
    expect(library.state.categories, isNot(contains('Test')));
    await expectLater(library.importCsv('wrong,header'), throwsFormatException);
    await expectLater(
      library.importCsv('x' * (5 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
  });

  test('invalid persisted state never silently resets the library', () async {
    storage.value = jsonEncode({'schemaVersion': 999});
    await expectLater(library.load(), throwsFormatException);
    expect(storage.value, jsonEncode({'schemaVersion': 999}));
  });

  test('theme, order and onboarding survive restart', () async {
    await library.setDark(true);
    await library.setSort(LinkSort.az);
    await library.finishOnboarding();
    final reloaded = BookmarkLibrary(storage);
    await reloaded.load();
    expect(reloaded.state.dark, isTrue);
    expect(reloaded.state.sort, LinkSort.az);
    expect(reloaded.state.onboarded, isTrue);
    reloaded.dispose();
  });
}
