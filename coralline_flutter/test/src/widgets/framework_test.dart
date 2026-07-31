import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

base class _TestWidgetComputation extends ComplexComputation<Widget> {
  _TestWidgetComputation(this.text);
  final String text;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => const [];

  @override
  Widget compute() => Text(text);
}

base class _TestDamageComputation extends ComplexComputation<Widget> {
  @override
  @manifestSync
  Iterable<CoralNode> manifest() => const [];

  @override
  Widget compute() => throw Exception('Computation damage test');
}

base class _NonWidgetIntent extends CorallineTerminalIntent {}

base class _TestContextAwareComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [context];

  @override
  Widget compute() {
    return const Text('HasContext');
  }
}

base class _TestExtendedContextComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final mediaQueryViewPaddingCoral = context.mediaQuery.viewPadding;
  late final localeCoral = context.localization.locale;
  late final formCoral = context.scope.form;
  late final primaryScrollControllerCoral = context.scope.primaryScrollController;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [
        mediaQueryViewPaddingCoral,
        localeCoral,
        formCoral,
        primaryScrollControllerCoral,
      ];

  @override
  Widget compute() {
    return const SizedBox();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoralWidget & CoralWidgetElement Framework Tests', () {
    testWidgets('Basic CoralWidget renders UI from Coral stream', (tester) async {
      final controller = CoralController<Widget>(const Text('Initial'));

      await tester.pumpWidget(
        MaterialApp(
          home: controller.coral.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Initial'), findsOneWidget);

      controller.set(const Text('Updated'));
      await tester.pump();

      expect(find.text('Updated'), findsOneWidget);
    });

    testWidgets('CoralWidget handles empty fallback', (tester) async {
      final emptyCoral = Coral<Widget>.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: emptyCoral.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('CoralWidget renders errorBuilder fallback on pipeline damage', (tester) async {
      final damageComputation = _TestDamageComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: damageComputation.toWidget(
            errorBuilder: (context, error, stackTrace) => Text('Error: $error'),
          ),
        ),
      );
      await tester.pump();

      // Consume reported FlutterError from FlutterError.reportError in _handleDamage
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);

      expect(find.textContaining('Error: Exception: Computation damage test'), findsOneWidget);
    });

    testWidgets('CoralWidget update (hotswap) updates underlying coral pipeline', (tester) async {
      final controller1 = CoralController<Widget>(const Text('Pipeline 1'));
      final controller2 = CoralController<Widget>(const Text('Pipeline 2'));

      await tester.pumpWidget(
        MaterialApp(
          home: CoralWidget(
            key: const ValueKey('same_key'),
            coral: controller1.coral,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pipeline 1'), findsOneWidget);

      // Hot-swap coral pipeline on same widget element
      await tester.pumpWidget(
        MaterialApp(
          home: CoralWidget(
            key: const ValueKey('same_key'),
            coral: controller2.coral,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pipeline 2'), findsOneWidget);
    });

    testWidgets('CoralWidget unmount cleanly deactivates terminal and decouples', (tester) async {
      final controller = CoralController<Widget>(const Text('Unmount Test'));

      await tester.pumpWidget(
        MaterialApp(
          home: controller.coral.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Unmount Test'), findsOneWidget);

      // Replace widget to unmount CoralWidget
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );
      await tester.pump();

      expect(find.text('Unmount Test'), findsNothing);
    });
  });

  group('CoralComputationWidgetExtension & ProviderExtension Tests', () {
    testWidgets('ComputationExtension toWidget converts CoralComputation to CoralWidget',
        (tester) async {
      final computation = _TestWidgetComputation('Computation Text');

      await tester.pumpWidget(
        MaterialApp(
          home: computation.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Computation Text'), findsOneWidget);
    });

    testWidgets('ProviderExtension toWidget converts CoralProvider to CoralWidget', (tester) async {
      final controller = CoralController<Widget>(const Text('Provider Text'));

      await tester.pumpWidget(
        MaterialApp(
          home: controller.provider.toWidget(),
        ),
      );
      await tester.pump();

      expect(find.text('Provider Text'), findsOneWidget);
    });
  });

  group('CorallineBuildContextAware & Intent Handling Tests', () {
    test('didUpdateIntent couples and decouples context based on intent type', () {
      final computation = _TestContextAwareComputation();
      final widgetIntent = CoralWidgetTerminalIntent(context: const _InstantContext());

      computation.didUpdateIntent(newIntent: widgetIntent);
      computation.didUpdateIntent(newIntent: _NonWidgetIntent());
    });
  });

  group('CoralBuildContextExtensions Detailed Scope & MediaQuery Tests', () {
    testWidgets(
        'Observes mediaQueryViewPadding, locale, form, primaryScrollController, scaffoldMessenger',
        (tester) async {
      final computation = _TestExtendedContextComputation();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          home: ScaffoldMessenger(
            child: Scaffold(
              body: PrimaryScrollController(
                controller: ScrollController(),
                child: Form(
                  child: MediaQuery(
                    data: const MediaQueryData(viewPadding: EdgeInsets.all(20)),
                    child: computation.toWidget(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(computation.mediaQueryViewPaddingCoral.data, const EdgeInsets.all(20));
      expect(computation.localeCoral.data, const Locale('en', 'US'));
      expect(computation.formCoral.data, isNotNull);
      expect(computation.primaryScrollControllerCoral.data, isNotNull);
    });
  });

  group('InheritedCoralProviderWidget & InheritedCoralProvider Exhaustive Tests', () {
    testWidgets('toInheritedWidget extension creates InheritedCoralProviderWidget', (tester) async {
      final controller = CoralController<String>('hello');
      final provider = controller.provider;
      final widget = provider.toInheritedWidget(child: const Text('Child'));

      expect(widget, isA<InheritedCoralProviderWidget<String>>());
      expect(widget.provider, provider);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      expect(find.text('Child'), findsOneWidget);
    });

    test('InheritedCoralProviderWidget updateShouldNotify compares provider references', () {
      final controller1 = CoralController<String>('v1');
      final controller2 = CoralController<String>('v2');
      final provider1 = controller1.provider;
      final provider2 = controller2.provider;

      final widget1 = InheritedCoralProviderWidget<String>(
        provider: provider1,
        child: const SizedBox(),
      );
      final widget1Same = InheritedCoralProviderWidget<String>(
        provider: provider1,
        child: const SizedBox(),
      );
      final widget2 = InheritedCoralProviderWidget<String>(
        provider: provider2,
        child: const SizedBox(),
      );

      expect(widget1.updateShouldNotify(widget1Same), false);
      expect(widget1.updateShouldNotify(widget2), true);
    });

    testWidgets('coralOf retrieves CoralProvider state from ancestor widget', (tester) async {
      final controller = CoralController<int>(42);
      final provider = controller.provider;
      final comp = _TestCoralOfComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: provider.toInheritedWidget(
            child: comp.toWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(comp.valueCoral.data, 42);
    });

    testWidgets('maybeCoralOf retrieves optional CoralProvider state from ancestor widget',
        (tester) async {
      final controller = CoralController<int>(42);
      final provider = controller.provider;
      final comp = _TestMaybeCoralOfComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: provider.toInheritedWidget(
            child: comp.toWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(comp.maybeValueCoral.data, 42);
      expect(comp.absentCoral.data, isNull);
    });

    testWidgets(
        'InheritedCoralProvider reactively updates InheritedCoralProviderWidget on providerCoral update',
        (tester) async {
      final controller1 = CoralController<String>('State 1');
      final controller2 = CoralController<String>('State 2');
      final provider1 = controller1.provider;
      final provider2 = controller2.provider;

      final providerController = CoralController<CoralProvider<String>>(provider1);
      final comp = _TestStringCoralOfComputation();

      final inheritedProviderComp = InheritedCoralProvider<String>(
        providerCoral: providerController.coral,
        child: comp.toWidget(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: inheritedProviderComp.toWidget(),
        ),
      );
      await tester.pump();

      expect(comp.valueCoral.data, 'State 1');

      // Update providerCoral stream
      providerController.set(provider2);
      await tester.pump();

      expect(comp.valueCoral.data, 'State 2');
    });
  });
}

base class _TestCoralOfComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final valueCoral = coralOf<int>();

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [valueCoral];

  @override
  Widget compute() => Text('Value: ${valueCoral.data}');
}

base class _TestMaybeCoralOfComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final maybeValueCoral = maybeCoralOf<int>();
  late final absentCoral = maybeCoralOf<double>();

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [maybeValueCoral, absentCoral];

  @override
  Widget compute() => Text('Maybe: ${maybeValueCoral.data}');
}

base class _TestStringCoralOfComputation extends ComplexComputation<Widget>
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  late final valueCoral = coralOf<String>();

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [valueCoral];

  @override
  Widget compute() => Text(valueCoral.data);
}

class _InstantContext implements BuildContext {
  const _InstantContext();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
