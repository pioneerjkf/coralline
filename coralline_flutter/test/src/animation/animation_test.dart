// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResilientAnimationController Exhaustive Member & Case Tests', () {
    // =========================================================================
    // 1. Constructors & Property Defaults
    // =========================================================================
    group('1. Constructors & Constraints', () {
      testWidgets('default bounded constructor initializes correctly',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  debugLabel: 'test_label',
                );
              },
            ),
          ),
        );

        expect(controller.broadcast, isFalse);
        expect(controller.lowerBound, equals(0.0));
        expect(controller.upperBound, equals(1.0));
        expect(controller.value, equals(0.0));
        expect(controller.duration, isNull);
        expect(controller.reverseDuration, isNull);
        expect(controller.debugLabel, equals('test_label'));
        expect(controller.animationBehavior, equals(AnimationBehavior.normal));
        expect(controller.vsync, isNotNull);

        controller.dispose();
      });

      testWidgets('asserts if upperBound < lowerBound',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                expect(
                  () => ResilientAnimationController(
                    vsync: vsync,
                    lowerBound: 1.0,
                    upperBound: 0.0,
                  ),
                  throwsAssertionError,
                );
              },
            ),
          ),
        );
      });

      testWidgets('unbounded constructor initializes infinite bounds',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController.unbounded(
                  vsync: vsync,
                  value: 42.0,
                  duration: const Duration(milliseconds: 200),
                );
              },
            ),
          ),
        );

        expect(controller.lowerBound, equals(double.negativeInfinity));
        expect(controller.upperBound, equals(double.infinity));
        expect(controller.value, equals(42.0));
        expect(controller.duration, equals(const Duration(milliseconds: 200)));
        expect(
            controller.animationBehavior, equals(AnimationBehavior.preserve));

        controller.dispose();
      });
    });

    // =========================================================================
    // 2. Dormant State Member Behavior (Getters, Setters, & Methods)
    // =========================================================================
    group('2. Dormant State All Members', () {
      testWidgets(
          'reads and writes dormant properties safely and notifies listeners',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        int notifyCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  value: 0.2,
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: const Duration(milliseconds: 150),
                );
              },
            ),
          ),
        );

        controller.addListener(() => notifyCount++);

        // Check initial dormant getters
        expect(controller.coral.isActivated, isFalse);
        expect(controller.isActivated, isFalse);
        expect(controller.isDeactivated, isTrue);
        expect(controller.isPaused, isFalse);
        expect(controller.isRunning, isFalse);
        expect(controller.view, isNull);
        expect(controller.value, equals(0.2));
        expect(controller.duration, equals(const Duration(milliseconds: 300)));
        expect(controller.reverseDuration,
            equals(const Duration(milliseconds: 150)));
        expect(controller.velocity, equals(0.0));
        expect(controller.lastElapsedDuration, isNull);
        expect(controller.isAnimating, isFalse);
        expect(controller.status, equals(AnimationStatus.dismissed));
        expect(controller.isDismissed, isTrue);
        expect(controller.isCompleted, isFalse);
        expect(controller.isForwardOrCompleted, isFalse);

        // Value setter in dormant state
        controller.value = 0.7;
        expect(controller.value, equals(0.7));
        expect(notifyCount, equals(1));

        // Duration setter in dormant state
        controller.duration = const Duration(milliseconds: 600);
        expect(controller.duration, equals(const Duration(milliseconds: 600)));
        expect(notifyCount, equals(2));

        // ReverseDuration setter in dormant state
        controller.reverseDuration = const Duration(milliseconds: 400);
        expect(controller.reverseDuration,
            equals(const Duration(milliseconds: 400)));
        expect(notifyCount, equals(3));

        // Reset in dormant state
        controller.reset();
        expect(controller.value, equals(0.0));
        expect(notifyCount, equals(4));

        // Resync and stop in dormant state (safe no-ops)
        controller
            .resync(tester.state(find.byType(TestWidget)) as TickerProvider);
        controller.stop();
        expect(controller.isAnimating, isFalse);

        // toStringDetails in dormant state
        expect(controller.toStringDetails(), contains('dormant'));

        controller.dispose();
      });

      testWidgets('status computation in dormant state for bounds',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  lowerBound: 0.0,
                  upperBound: 1.0,
                );
              },
            ),
          ),
        );

        // Value == lowerBound -> dismissed
        controller.value = 0.0;
        expect(controller.status, equals(AnimationStatus.dismissed));
        expect(controller.isDismissed, isTrue);

        // Value == upperBound -> completed
        controller.value = 1.0;
        expect(controller.status, equals(AnimationStatus.completed));
        expect(controller.isCompleted, isTrue);

        // Intermediate value -> dismissed in dormant
        controller.value = 0.5;
        expect(controller.status, equals(AnimationStatus.dismissed));

        controller.dispose();
      });

      testWidgets('all driving methods throw StateError in dormant state',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          ),
        );

        expect(() => controller.forward(), throwsStateError);
        expect(() => controller.reverse(), throwsStateError);
        expect(() => controller.toggle(), throwsStateError);
        expect(() => controller.animateTo(0.8), throwsStateError);
        expect(() => controller.animateBack(0.2), throwsStateError);
        expect(() => controller.repeat(), throwsStateError);
        expect(() => controller.fling(), throwsStateError);
        expect(
          () => controller.animateWith(GravitySimulation(9.8, 0.0, 1.0, 0.0)),
          throwsStateError,
        );
        expect(
          () =>
              controller.animateBackWith(GravitySimulation(9.8, 1.0, 0.0, 0.0)),
          throwsStateError,
        );

        controller.dispose();
      });
    });

    // =========================================================================
    // 3. Active State Member Behavior (All Driving Methods & Engine Operations)
    // =========================================================================
    group('3. Active State Driving Methods & Ticker Simulation', () {
      testWidgets('forward & reverse drive animation properly when active',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 200),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        expect(controller.isActivated, isTrue);
        expect(controller.view, isNotNull);

        // Test forward()
        final forwardFuture = controller.forward();
        expect(controller.isAnimating, isTrue);
        expect(controller.status, equals(AnimationStatus.forward));

        await tester.pumpAndSettle();
        await forwardFuture;

        expect(controller.value, equals(1.0));
        expect(controller.status, equals(AnimationStatus.completed));
        expect(controller.isCompleted, isTrue);

        // Test reverse()
        final reverseFuture = controller.reverse();
        expect(controller.isAnimating, isTrue);
        expect(controller.status, equals(AnimationStatus.reverse));

        await tester.pumpAndSettle();
        await reverseFuture;

        expect(controller.value, equals(0.0));
        expect(controller.status, equals(AnimationStatus.dismissed));

        // Test forward(from: 0.5)
        controller.forward(from: 0.5);
        expect(controller.value, equals(0.5));
        await tester.pumpAndSettle();
        expect(controller.value, equals(1.0));

        terminal.deactivate();
        controller.dispose();
      });

      testWidgets('toggle switches direction correctly',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 100),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        // Initial state is dismissed -> toggle moves forward
        controller.toggle();
        expect(controller.status, equals(AnimationStatus.forward));
        await tester.pumpAndSettle();
        expect(controller.status, equals(AnimationStatus.completed));

        // State is completed -> toggle moves in reverse
        controller.toggle();
        expect(controller.status, equals(AnimationStatus.reverse));
        await tester.pumpAndSettle();
        expect(controller.status, equals(AnimationStatus.dismissed));

        terminal.deactivate();
        controller.dispose();
      });

      testWidgets('animateTo and animateBack drive towards target values',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 200),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        controller.animateTo(0.6, curve: Curves.easeIn);
        await tester.pumpAndSettle();
        expect(controller.value, closeTo(0.6, 0.01));

        controller.animateBack(0.2, curve: Curves.easeOut);
        await tester.pumpAndSettle();
        expect(controller.value, closeTo(0.2, 0.01));

        terminal.deactivate();
        controller.dispose();
      });

      testWidgets('repeat drives cyclic animation',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 100),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        controller.repeat(count: 2, reverse: true);
        expect(controller.isAnimating, isTrue);

        await tester.pump(const Duration(milliseconds: 100)); // Forward pass
        await tester.pump(const Duration(milliseconds: 100)); // Reverse pass
        await tester.pumpAndSettle();

        expect(controller.isAnimating, isFalse);

        terminal.deactivate();
        controller.dispose();
      });

      testWidgets('fling drives physics simulation',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 200),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        controller.fling(velocity: 2.0);
        expect(controller.isAnimating, isTrue);

        await tester.pumpAndSettle();
        expect(controller.value, equals(1.0));

        terminal.deactivate();
        controller.dispose();
      });

      testWidgets('animateWith and animateBackWith drive custom simulation',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  duration: const Duration(milliseconds: 200),
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        final sim = FrictionSimulation(0.1, 0.0, 1.0);
        controller.animateWith(sim);
        expect(controller.isAnimating, isTrue);
        await tester.pumpAndSettle();

        final backSim = FrictionSimulation(0.1, 1.0, -1.0);
        controller.animateBackWith(backSim);
        expect(controller.isAnimating, isTrue);
        await tester.pumpAndSettle();

        terminal.deactivate();
        controller.dispose();
      });
    });

    // =========================================================================
    // 4. State Continuity across Dormant ↔ Active Transitions
    // =========================================================================
    group('4. State Continuity & Lifecycle Transitions', () {
      testWidgets(
          'preserves parameters staged in dormant state upon activation',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                );
              },
            ),
          ),
        );

        // Stage parameters while dormant
        controller.value = 0.4;
        controller.duration = const Duration(milliseconds: 400);
        controller.reverseDuration = const Duration(milliseconds: 250);

        // Activate
        terminal = controller.coral.toTerminal(() {});
        terminal.activate();

        // Verify active engine inherited staged parameters
        expect(controller.value, equals(0.4));
        expect(controller.duration, equals(const Duration(milliseconds: 400)));
        expect(controller.reverseDuration,
            equals(const Duration(milliseconds: 250)));

        // Deactivate and check fallback persistence
        terminal.deactivate();
        expect(controller.isActivated, isFalse);
        expect(controller.value, equals(0.4));
        expect(controller.duration, equals(const Duration(milliseconds: 400)));

        controller.dispose();
      });
    });

    // =========================================================================
    // 5. Broadcaster vs Single Provider Strategy
    // =========================================================================
    group('5. Broadcast Strategy', () {
      testWidgets('broadcast=true allows multiple subscribers without error',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal1;
        late CoralTerminal<double> terminal2;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  broadcast: true,
                  duration: const Duration(milliseconds: 100),
                );
              },
            ),
          ),
        );

        terminal1 = controller.coral.toTerminal(() {});
        terminal2 = controller.coral.toTerminal(() {});

        terminal1.activate();
        terminal2.activate();
        await tester.pump();

        expect(terminal1.isActivated, isTrue);
        expect(terminal2.isActivated, isTrue);

        terminal1.deactivate();
        terminal2.deactivate();

        controller.dispose();
      });
    });

    // =========================================================================
    // 6. Utility & Mixin Methods (drive, toStringDetails)
    // =========================================================================
    group('6. Transformations & Debugging', () {
      testWidgets('drive method creates transformed Animation',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  value: 0.5,
                );
              },
            ),
          ),
        );

        final tween = Tween<double>(begin: 0.0, end: 200.0);
        final Animation<double> drivenAnimation = controller.drive(tween);

        expect(drivenAnimation.value, equals(100.0));

        controller.dispose();
      });

      testWidgets('toStringDetails provides diagnostic info in active state',
          (WidgetTester tester) async {
        late ResilientAnimationController controller;
        late CoralTerminal<double> terminal;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidget(
              onInit: (vsync) {
                controller = ResilientAnimationController(
                  vsync: vsync,
                  debugLabel: 'my_anim',
                );
                terminal = controller.coral.toTerminal(() {});
                terminal.activate();
              },
            ),
          ),
        );

        final details = controller.toStringDetails();
        expect(details, isNotEmpty);

        terminal.deactivate();
        controller.dispose();
      });
    });
  });
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key, required this.onInit});

  final void Function(TickerProvider vsync) onInit;

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
