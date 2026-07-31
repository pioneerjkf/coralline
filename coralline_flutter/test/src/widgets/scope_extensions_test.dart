// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline/coralline.dart';
import 'package:coralline_flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoralBuildContext Core Extensions Tests', () {
    // =========================================================================
    // 1. MediaQuery Proxy & Extensions
    // =========================================================================
    group('MediaQueryProxy Tests', () {
      testWidgets('observes all mediaQuery properties reactively', (WidgetTester tester) async {
        final computation = _TestMediaQueryComputation();

        Widget buildWidget(MediaQueryData data) {
          return MaterialApp(
            home: MediaQuery(
              data: data,
              child: computation.toWidget(),
            ),
          );
        }

        const initialData = MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.all(10),
          viewInsets: EdgeInsets.all(20),
          viewPadding: EdgeInsets.all(15),
          platformBrightness: Brightness.dark,
          devicePixelRatio: 2.0,
        );

        await tester.pumpWidget(buildWidget(initialData));
        await tester.pump();

        expect(computation.dataCoral.data, equals(initialData));
        expect(computation.sizeCoral.data, equals(const Size(800, 600)));
        expect(computation.paddingCoral.data, equals(const EdgeInsets.all(10)));
        expect(computation.viewInsetsCoral.data, equals(const EdgeInsets.all(20)));
        expect(computation.viewPaddingCoral.data, equals(const EdgeInsets.all(15)));
        expect(computation.orientationCoral.data, equals(Orientation.landscape));
        expect(computation.platformBrightnessCoral.data, equals(Brightness.dark));
        expect(computation.devicePixelRatioCoral.data, equals(2.0));

        const updatedData = MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.all(5),
          viewInsets: EdgeInsets.all(0),
          viewPadding: EdgeInsets.all(5),
          platformBrightness: Brightness.light,
          devicePixelRatio: 3.0,
        );

        await tester.pumpWidget(buildWidget(updatedData));
        await tester.pump();

        expect(computation.sizeCoral.data, equals(const Size(400, 800)));
        expect(computation.paddingCoral.data, equals(const EdgeInsets.all(5)));
        expect(computation.orientationCoral.data, equals(Orientation.portrait));
        expect(computation.platformBrightnessCoral.data, equals(Brightness.light));
        expect(computation.devicePixelRatioCoral.data, equals(3.0));
      });
    });

    // =========================================================================
    // 2. Localization Proxy & Text Directionality
    // =========================================================================
    group('LocalizationProxy Tests', () {
      testWidgets('observes locale and text direction reactively', (WidgetTester tester) async {
        final computation = _TestLocalizationComputation();

        Widget buildWidget(Locale locale, TextDirection direction) {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                return Localizations.override(
                  context: context,
                  locale: locale,
                  child: Directionality(
                    textDirection: direction,
                    child: computation.toWidget(),
                  ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildWidget(const Locale('en'), TextDirection.ltr));
        await tester.pump();

        expect(computation.localeCoral.data, equals(const Locale('en')));
        expect(computation.directionCoral.data, equals(TextDirection.ltr));

        await tester.pumpWidget(buildWidget(const Locale('fr'), TextDirection.rtl));
        await tester.pump();

        expect(computation.localeCoral.data, equals(const Locale('fr')));
        expect(computation.directionCoral.data, equals(TextDirection.rtl));
      });
    });

    // =========================================================================
    // 3. Text Proxy & DefaultTextStyle
    // =========================================================================
    group('TextProxy Tests', () {
      testWidgets('observes default text style reactively', (WidgetTester tester) async {
        final computation = _TestTextComputation();

        Widget buildWidget(TextStyle style) {
          return MaterialApp(
            home: DefaultTextStyle(
              style: style,
              child: computation.toWidget(),
            ),
          );
        }

        await tester.pumpWidget(buildWidget(const TextStyle(fontSize: 16.0)));
        await tester.pump();

        expect(computation.defaultStyleCoral.data.style.fontSize, equals(16.0));

        await tester.pumpWidget(buildWidget(const TextStyle(fontSize: 28.0)));
        await tester.pump();

        expect(computation.defaultStyleCoral.data.style.fontSize, equals(28.0));
      });
    });

    // =========================================================================
    // 4. Scope Proxy (Focus, Form, PrimaryScrollController, Navigator, Overlay, Scrollable)
    // =========================================================================
    group('ScopeProxy Tests', () {
      testWidgets('observes FocusScopeNode reactively', (WidgetTester tester) async {
        final computation = _TestFocusScopeComputation();

        await tester.pumpWidget(
          MaterialApp(
            home: computation.toWidget(),
          ),
        );
        await tester.pump();

        expect(computation.focusCoral.data, isNotNull);
      });

      testWidgets('observes FormState (present vs null)', (WidgetTester tester) async {
        final computation = _TestFormScopeComputation();

        // Outside Form
        await tester.pumpWidget(
          MaterialApp(
            home: computation.toWidget(),
          ),
        );
        await tester.pump();

        expect(computation.formCoral.data, isNull);

        // Inside Form
        final insideComputation = _TestFormScopeComputation();
        await tester.pumpWidget(
          MaterialApp(
            home: Form(
              child: insideComputation.toWidget(),
            ),
          ),
        );
        await tester.pump();

        expect(insideComputation.formCoral.data, isNotNull);
      });

      testWidgets('observes PrimaryScrollController, Navigator, Overlay, Scrollable',
          (WidgetTester tester) async {
        final computation = _TestScopeControllersComputation();
        final controller = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrimaryScrollController(
                controller: controller,
                child: Scrollable(
                  controller: controller,
                  viewportBuilder: (context, position) {
                    return computation.toWidget();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(computation.scrollControllerCoral.data, isNotNull);
        expect(computation.navigatorCoral.data, isNotNull);
        expect(computation.overlayCoral.data, isNotNull);
        expect(computation.scrollableCoral.data, isNotNull);

        controller.dispose();
      });


    });

    // =========================================================================
    // 5. IconTheme Extension
    // =========================================================================
    group('IconThemeExtension Tests', () {
      testWidgets('observes IconThemeData reactively', (WidgetTester tester) async {
        final computation = _TestIconThemeComputation();

        Widget buildWidget(Color color) {
          return MaterialApp(
            home: IconTheme(
              data: IconThemeData(color: color),
              child: computation.toWidget(),
            ),
          );
        }

        await tester.pumpWidget(buildWidget(Colors.red));
        await tester.pump();

        expect(computation.iconThemeCoral.data.color, equals(Colors.red));

        await tester.pumpWidget(buildWidget(Colors.blue));
        await tester.pump();

        expect(computation.iconThemeCoral.data.color, equals(Colors.blue));
      });
    });
  });
}

base class _TestMediaQueryComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final dataCoral = context.mediaQuery.data;
  late final sizeCoral = context.mediaQuery.size;
  late final paddingCoral = context.mediaQuery.padding;
  late final viewInsetsCoral = context.mediaQuery.viewInsets;
  late final viewPaddingCoral = context.mediaQuery.viewPadding;
  late final orientationCoral = context.mediaQuery.orientation;
  late final platformBrightnessCoral = context.mediaQuery.platformBrightness;
  late final devicePixelRatioCoral = context.mediaQuery.devicePixelRatio;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        dataCoral,
        sizeCoral,
        paddingCoral,
        viewInsetsCoral,
        viewPaddingCoral,
        orientationCoral,
        platformBrightnessCoral,
        devicePixelRatioCoral,
      ];

  @override
  Widget compute() => Container();
}

base class _TestLocalizationComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final localeCoral = context.localization.locale;
  late final directionCoral = context.localization.direction;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [localeCoral, directionCoral];

  @override
  Widget compute() => Container();
}

base class _TestTextComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final defaultStyleCoral = context.text.defaultStyle;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [defaultStyleCoral];

  @override
  Widget compute() => Container();
}

base class _TestFocusScopeComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final focusCoral = context.scope.focus;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [focusCoral];

  @override
  Widget compute() => Container();
}

base class _TestFormScopeComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final formCoral = context.scope.form;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [formCoral];

  @override
  Widget compute() => Container();
}

base class _TestScopeControllersComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final scrollControllerCoral = context.scope.primaryScrollController;
  late final navigatorCoral = context.scope.navigator;
  late final overlayCoral = context.scope.overlay;
  late final scrollableCoral = context.scope.scrollable;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        scrollControllerCoral,
        navigatorCoral,
        overlayCoral,
        scrollableCoral,
      ];

  @override
  Widget compute() => Container();
}

base class _TestIconThemeComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final iconThemeCoral = context.iconTheme;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [iconThemeCoral];

  @override
  Widget compute() => Container();
}
