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

base class _TestContextAwareMultiTickerComputation
    extends ComplexComputation<Widget>
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

base class _TestContextAwareSingleTickerComputation
    extends ComplexComputation<Widget>
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
      final computation = _TestMultiTickerLifecycleAware();
      final ticker1 = computation.createTicker((elapsed) {});
      final ticker2 = computation.createTicker((elapsed) {});

      expect(ticker1, isNotNull);
      expect(ticker2, isNotNull);
      expect(ticker1, isNot(same(ticker2)));

      computation.didDeactivate();
    });

    test('didPause and didResume mute and unmute tickers', () {
      final computation = _TestMultiTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});

      expect(ticker.muted, false);
      computation.didPause();
      expect(ticker.muted, true);
      computation.didResume();
      expect(ticker.muted, false);

      computation.didDeactivate();
    });

    test('didDeactivate disposes created tickers', () {
      final computation = _TestMultiTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});

      expect(ticker.isActive, false);
      computation.didDeactivate();
    });

    test('didDeactivate asserts when an active ticker exists', () {
      final computation = _TestMultiTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});
      ticker.start();

      expect(ticker.isActive, true);
      expect(
        () => computation.didDeactivate(),
        throwsA(isA<AssertionError>()),
      );

      ticker.stop();
      computation.didDeactivate();
    });

    testWidgets(
        'TickerMode updates mute status when wrapped in CorallineBuildContextAware',
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
      final computation = _TestSingleTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});

      expect(ticker, isNotNull);
      computation.didDeactivate();
    });

    test('didPause and didResume mute and unmute ticker', () {
      final computation = _TestSingleTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});

      expect(ticker.muted, false);
      computation.didPause();
      expect(ticker.muted, true);
      computation.didResume();
      expect(ticker.muted, false);

      computation.didDeactivate();
    });

    test('createTicker asserts when multiple tickers are created', () {
      final computation = _TestSingleTickerLifecycleAware();
      computation.createTicker((elapsed) {});

      expect(
        () => computation.createTicker((elapsed) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('didDeactivate asserts when active ticker exists', () {
      final computation = _TestSingleTickerLifecycleAware();
      final ticker = computation.createTicker((elapsed) {});
      ticker.start();

      expect(ticker.isActive, true);
      expect(
        () => computation.didDeactivate(),
        throwsA(isA<AssertionError>()),
      );

      ticker.stop();
      computation.didDeactivate();
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

    testWidgets('didPause and didResume interact correctly with TickerMode',
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
