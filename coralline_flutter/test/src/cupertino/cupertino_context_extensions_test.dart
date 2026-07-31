// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline/coralline.dart';
import 'package:coralline_flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

base class TestCupertinoContextComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final themeCoral = context.cupertino.themeData;
  late final primaryColorCoral = context.cupertino.primaryColor;
  late final textThemeCoral = context.cupertino.textTheme;
  late final barBgCoral = context.cupertino.barBackgroundColor;
  late final scaffoldBgCoral = context.cupertino.scaffoldBackgroundColor;
  late final brightnessCoral = context.cupertino.theme.brightness;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        themeCoral,
        primaryColorCoral,
        textThemeCoral,
        barBgCoral,
        scaffoldBgCoral,
        brightnessCoral,
      ];

  @override
  Widget compute() {
    final theme = themeCoral.data;
    final primary = primaryColorCoral.data;
    final brightness = brightnessCoral.data;

    return Column(
      children: [
        Text('PrimaryColor: ${primary.toARGB32()}'),
        Text('Brightness: ${brightness.name}'),
        Text('BarBg: ${theme.barBackgroundColor.toARGB32()}'),
      ],
    );
  }
}

void main() {
  group('CoralBuildContextCupertinoExtension Tests', () {
    testWidgets('observes CupertinoTheme property updates reactively',
        (WidgetTester tester) async {
      final computation = TestCupertinoContextComputation();

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            primaryColor: Color(0xFF0000FF),
            brightness: Brightness.light,
          ),
          home: computation.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Brightness: light'), findsOneWidget);
      expect(
        find.text('PrimaryColor: ${const Color(0xFF0000FF).toARGB32()}'),
        findsOneWidget,
      );

      // Re-pump widget with dark theme and red primary color
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            primaryColor: Color(0xFFFF0000),
            brightness: Brightness.dark,
          ),
          home: computation.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Brightness: dark'), findsOneWidget);
      expect(
        find.text('PrimaryColor: ${const Color(0xFFFF0000).toARGB32()}'),
        findsOneWidget,
      );
    });

    testWidgets('observes userInterfaceLevel and extra theme proxy properties',
        (WidgetTester tester) async {
      final computation = _TestUserInterfaceLevelComputation();

      Widget buildWidget(CupertinoUserInterfaceLevelData level) {
        return CupertinoApp(
          theme: const CupertinoThemeData(
            primaryColor: Color(0xFF00FF00),
            primaryContrastingColor: Color(0xFF000000),
            scaffoldBackgroundColor: Color(0xFFEEEEEE),
            barBackgroundColor: Color(0xFFCCCCCC),
          ),
          home: CupertinoUserInterfaceLevel(
            data: level,
            child: computation.toWidget(),
          ),
        );
      }

      await tester
          .pumpWidget(buildWidget(CupertinoUserInterfaceLevelData.base));
      await tester.pump();

      expect(computation.levelCoral.data,
          equals(CupertinoUserInterfaceLevelData.base));
      expect(computation.primaryContrastingCoral.data,
          equals(const Color(0xFF000000)));
      expect(computation.scaffoldBgCoral.data, equals(const Color(0xFFEEEEEE)));
      expect(computation.barBgCoral.data, equals(const Color(0xFFCCCCCC)));
      expect(computation.textThemeCoral.data, isNotNull);

      await tester
          .pumpWidget(buildWidget(CupertinoUserInterfaceLevelData.elevated));
      await tester.pump();

      expect(computation.levelCoral.data,
          equals(CupertinoUserInterfaceLevelData.elevated));
    });
  });
}

base class _TestUserInterfaceLevelComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final levelCoral = context.cupertino.userInterfaceLevel;
  late final primaryContrastingCoral =
      context.cupertino.theme.primaryContrastingColor;
  late final scaffoldBgCoral = context.cupertino.scaffoldBackgroundColor;
  late final barBgCoral = context.cupertino.barBackgroundColor;
  late final textThemeCoral = context.cupertino.textTheme;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        levelCoral,
        primaryContrastingCoral,
        scaffoldBgCoral,
        barBgCoral,
        textThemeCoral,
      ];

  @override
  Widget compute() => Container();
}
