import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

base class _TestMultiTickerLifecycleAware
    with
        CorallineLifecycleAware,
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        TickerProviderCorallineLifecycleAwareMixin {}

base class _TestSingleTickerLifecycleAware
    with
        CorallineLifecycleAware,
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        SingleTickerProviderCorallineLifecycleAwareMixin {}

base class _TestContextAwareMultiTickerComputation extends ComplexComputation<Widget>
    with
        CorallineLifecycleAware,
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        TickerProviderCorallineLifecycleAwareMixin {
  Ticker? ticker;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [context];

  @override
  void didActivate() {
    super.didActivate();
    ticker = createTicker((elapsed) {});
  }

  @override
  Widget compute() => const SizedBox();
}

base class _TestContextAwareSingleTickerComputation extends ComplexComputation<Widget>
    with
        CorallineLifecycleAware,
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        SingleTickerProviderCorallineLifecycleAwareMixin {
  Ticker? ticker;

  @override
  @manifestSync
  Iterable<CoralNode> manifest() => [context];

  @override
  void didActivate() {
    super.didActivate();
    ticker = createTicker((elapsed) {});
  }

  @override
  Widget compute() => const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TickerProviderCorallineLifecycleAwareMixin Tests', () {
    test('createTicker creates and manages multiple tickers', () {
      final Computation = _TestMultiTickerLifecycleAware();
      final ticker1 = Computation.createTicker((elapsed) {});
      final ticker2 = Computation.createTicker((elapsed) {});

      expect(ticker1, isNotNull);
      expect(ticker2, isNotNull);
      expect(ticker1, isNot(same(ticker2)));

      Computation.didDeactivate();
    });

    test('didPause and didResume mute and unmute tickers', () {
      final Computation = _TestMultiTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});

      expect(ticker.muted, false);
      Computation.didPause();
      expect(ticker.muted, true);
      Computation.didResume();
      expect(ticker.muted, false);

      Computation.didDeactivate();
    });

    test('didDeactivate disposes created tickers', () {
      final Computation = _TestMultiTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});

      expect(ticker.isActive, false);
      Computation.didDeactivate();
    });

    test('didDeactivate asserts when an active ticker exists', () {
      final Computation = _TestMultiTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});
      ticker.start();

      expect(ticker.isActive, true);
      expect(
        () => Computation.didDeactivate(),
        throwsA(isA<AssertionError>()),
      );

      ticker.stop();
      Computation.didDeactivate();
    });

    testWidgets('TickerMode updates mute status when wrapped in CorallineBuildContextAware',
        (tester) async {
      final computation = _TestContextAwareMultiTickerComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: true,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker, isNotNull);
      expect(computation.ticker!.muted, false);

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker!.muted, true);
    });
  });

  group('SingleTickerProviderCorallineLifecycleAwareMixin Tests', () {
    test('createTicker creates a single ticker successfully', () {
      final Computation = _TestSingleTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});

      expect(ticker, isNotNull);
      Computation.didDeactivate();
    });

    test('didPause and didResume mute and unmute ticker', () {
      final Computation = _TestSingleTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});

      expect(ticker.muted, false);
      Computation.didPause();
      expect(ticker.muted, true);
      Computation.didResume();
      expect(ticker.muted, false);

      Computation.didDeactivate();
    });

    test('createTicker asserts when multiple tickers are created', () {
      final Computation = _TestSingleTickerLifecycleAware();
      Computation.createTicker((elapsed) {});

      expect(
        () => Computation.createTicker((elapsed) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('didDeactivate asserts when active ticker exists', () {
      final Computation = _TestSingleTickerLifecycleAware();
      final ticker = Computation.createTicker((elapsed) {});
      ticker.start();

      expect(ticker.isActive, true);
      expect(
        () => Computation.didDeactivate(),
        throwsA(isA<AssertionError>()),
      );

      ticker.stop();
      Computation.didDeactivate();
    });

    testWidgets(
        'TickerMode updates mute status in SingleTickerProviderCorallineLifecycleAwareMixin',
        (tester) async {
      final computation = _TestContextAwareSingleTickerComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: true,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker, isNotNull);
      expect(computation.ticker!.muted, false);

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker!.muted, true);
    });

    testWidgets('didPause and didResume interact correctly with TickerMode', (tester) async {
      final computation = _TestContextAwareSingleTickerComputation();

      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: true,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker!.muted, false);

      // Explicitly pause the computation
      computation.didPause();
      expect(computation.ticker!.muted, true);

      // Resuming while TickerMode is disabled keeps ticker muted
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: computation.toWidget(),
          ),
        ),
      );

      computation.didResume();
      expect(computation.ticker!.muted, true);

      // Enabling TickerMode unmutes ticker
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: true,
            child: computation.toWidget(),
          ),
        ),
      );

      expect(computation.ticker!.muted, false);
    });
  });
}
