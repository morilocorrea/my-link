import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylink/screens/about_screen.dart';
import 'package:mylink/theme/app_theme.dart';
import 'package:mylink/widgets/my_link_logo.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AboutScreen(),
    );
  }

  group('AboutScreen Widget Tests', () {
    testWidgets('renders all visual elements and details', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('Sobre'), findsOneWidget);

      // Header logo & branding
      expect(find.byType(MyLinkLogoBadge), findsOneWidget);
      expect(find.text('MyLink'), findsOneWidget);
      expect(find.text('Seus links, sempre à mão'), findsOneWidget);

      // Section headers
      expect(find.text('DETALHES TÉCNICOS'), findsOneWidget);
      expect(find.text('LINKS ÚTEIS'), findsOneWidget);

      // Technical details
      expect(find.text('Versão'), findsOneWidget);
      expect(find.text('0.1.0'), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Desenvolvedor'), findsOneWidget);
      expect(find.text('SisCORR Desenvolvimento'), findsWidgets);

      // Useful links
      expect(find.text('Política de Privacidade'), findsOneWidget);
    });

    testWidgets('tapping Política de Privacidade does not throw unhandled error', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final privacyTile = find.text('Política de Privacidade');
      expect(privacyTile, findsOneWidget);

      await tester.tap(privacyTile);
      await tester.pump();
      // Should not throw unhandled exception
    });
  });
}
