import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylink/widgets/my_link_logo.dart';

void main() {
  testWidgets('MyLinkLogo renders SvgPicture with correct size and color filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MyLinkLogo(size: 64, color: Colors.blue),
        ),
      ),
    );

    final svgFinder = find.byType(SvgPicture);
    expect(svgFinder, findsOneWidget);

    final svgWidget = tester.widget<SvgPicture>(svgFinder);
    expect(svgWidget.width, 64);
    expect(svgWidget.height, 64);
  });

  testWidgets('MyLinkLogoBadge renders container and nested logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: const Scaffold(
          body: MyLinkLogoBadge(size: 48, iconSize: 28, borderRadius: 14),
        ),
      ),
    );

    expect(find.byType(MyLinkLogoBadge), findsOneWidget);
    expect(find.byType(MyLinkLogo), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svgWidget.width, 28);
    expect(svgWidget.height, 28);
  });
}
