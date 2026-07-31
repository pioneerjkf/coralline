// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline/coralline.dart';
import 'package:coralline_flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

base class TestMaterialContextComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final themeCoral = context.material.theme.data;
  late final colorSchemeCoral = context.material.colorScheme;
  late final textThemeCoral = context.material.theme.textTheme;
  late final scaffoldMessengerCoral = context.material.scaffoldMessenger;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        themeCoral,
        colorSchemeCoral,
        textThemeCoral,
        scaffoldMessengerCoral,
      ];

  @override
  Widget compute() {
    final colorScheme = colorSchemeCoral.data;

    return Column(
      children: [
        Text('PrimaryColor: ${colorScheme.primary.toARGB32()}'),
      ],
    );
  }
}

void main() {
  group('CoralBuildContextMaterialExtension Tests', () {
    testWidgets('observes Material Theme & ColorScheme updates reactively',
        (WidgetTester tester) async {
      final computation = TestMaterialContextComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.red)),
            child: computation.toWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(computation.colorSchemeCoral.data.primary, Colors.red);
      expect(find.text('PrimaryColor: ${Colors.red.toARGB32()}'), findsOneWidget);

      // Change Theme ColorScheme
      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue)),
            child: computation.toWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(computation.colorSchemeCoral.data.primary, Colors.blue);
      expect(find.text('PrimaryColor: ${Colors.blue.toARGB32()}'), findsOneWidget);
    });

    testWidgets('observes scaffold.state and scaffold.messenger reactively',
        (WidgetTester tester) async {
      final computation = _TestScaffoldComputation();

      // Inside Scaffold
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: computation.toWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(computation.scaffoldStateCoral.data, isNotNull);
      expect(computation.messengerCoral.data, isNotNull);

      // Trigger SnackBar via messenger
      computation.messengerCoral.data.showSnackBar(
        const SnackBar(content: Text('Hello Coral')),
      );
      await tester.pump();

      expect(find.text('Hello Coral'), findsOneWidget);

      // Outside Scaffold (scaffoldState should be null)
      final outsideComputation = _TestScaffoldComputation();
      await tester.pumpWidget(
        MaterialApp(
          home: outsideComputation.toWidget(),
        ),
      );
      await tester.pump();

      expect(outsideComputation.scaffoldStateCoral.data, isNull);
    });

    testWidgets('observes theme.textTheme and theme.iconTheme reactively',
        (WidgetTester tester) async {
      final computation = _TestThemeComputation();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 24.0)),
            iconTheme: const IconThemeData(color: Colors.green),
          ),
          home: computation.toWidget(),
        ),
      );
      await tester.pump();

      expect(computation.textThemeCoral.data.bodyLarge?.fontSize, equals(24.0));
      expect(computation.iconThemeCoral.data.color, equals(Colors.green));
    });
  });
}

base class _TestScaffoldComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final scaffoldStateCoral = context.material.scaffold.state;
  late final messengerCoral = context.material.scaffoldMessenger;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [scaffoldStateCoral, messengerCoral];

  @override
  Widget compute() => Container();
}

base class _TestThemeComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final textThemeCoral = context.material.textTheme;
  late final iconThemeCoral = context.material.theme.iconTheme;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [textThemeCoral, iconThemeCoral];

  @override
  Widget compute() => Container();
}
