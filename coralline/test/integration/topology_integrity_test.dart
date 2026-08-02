// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

final class TestTerminalIntent extends CorallineTerminalIntent {
  Object? caughtError;
  StackTrace? caughtStackTrace;

  @override
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    caughtError = error;
    caughtStackTrace = stackTrace;
  }
}

void main() {
  group('1. Topology Integrity & Connection Rules', () {
    test('Ownership Stealing Prevention: 1:1 Coral cannot attach to multiple terminals', () {
      final source = CoralController<int>(0);

      // First terminal successfully takes ownership
      final terminalA = source.coral.toTerminal(() {});
      terminalA.activate();

      // Second terminal attempts to attach to the same 1:1 coral
      final terminalB = source.coral.toTerminal(() {});
      terminalB.activate();

      expect(
        terminalB.snapshot.isDamaged,
        true,
        reason:
            'Ownership stealing causes an exception which is gracefully caught by the optimistic handshake, leaving the terminal damaged',
      );

      terminalA.deactivate();
      terminalB.deactivate();
    });

    test('Broadcaster allows multiple terminals (1:N)', () {
      final source = CoralController<int>(0, broadcast: true);

      final terminalA = source.coral.toTerminal(() {});
      final terminalB = source.coral.toTerminal(() {});

      terminalA.activate();
      expect(() => terminalB.activate(), returnsNormally, reason: 'Broadcaster safely allows 1:N attachment');

      terminalA.deactivate();
      terminalB.deactivate();
    });

    test('Self-referencing & Cyclic Dependency (Handled safely by framework limits)', () {
      // Due to the declarative and directional nature of CoralNode APIs (A -> B -> C),
      // it is inherently difficult to create a cyclic dependency using public APIs.
      // We verify that combining nodes doesn't accidentally cause infinite loops.
      final a = CoralController<int>(1);
      final b = CoralController<int>(2);

      final trunk = [a.coral, b.coral].toTrunk();
      final terminal = trunk.toTerminal(() {});

      terminal.activate();
      expect(terminal.linesOrNull?.length, 2);
      terminal.deactivate();
    });

    test('Broadcaster acts as an Intent Firewall and insulates upstream nodes from downstream intents', () {
      final intent = TestTerminalIntent();
      final source = CoralController<int>(10);
      final broadcaster = source.coral.toBroadcaster();
      final branch = broadcaster.coral;

      final terminal = CoralTerminal.withIntent(branch, intent: intent, onDirty: () {});
      terminal.activate();

      expect(terminal.snapshot.data, 10);
      expect(broadcaster.isActivated, isTrue);

      terminal.deactivate();
    });

    test(
        'Synchronous circular mutation during notification triggers reentrancy error caught by terminal intent handler',
        () {
      final intent = TestTerminalIntent();
      final controllerA = CoralController<int>(1);

      final terminal = CoralTerminal.withIntent(
        controllerA.coral,
        intent: intent,
        onDirty: () {
          controllerA.snapshot;
          controllerA.set(100);
        },
      );
      terminal.activate();

      controllerA.set(2);

      expect(intent.caughtError, isA<CoralNodeReentrancyError>());

      terminal.deactivate();
    });

    test('Multi-level Diverge and Converge pipeline clean deactivation and propagation', () {
      final controller = CoralController<int>(5);

      final divergedTrunk = controller.coral.diverge((val) => [
            Coral.data(val * 2),
            Coral.data(val * 3),
          ]);

      final convergedCoral = divergedTrunk.converge((lines) => Coral.data(
            lines.fold<int>(0, (sum, line) => sum + line.data),
          ));

      final terminal = convergedCoral.toTerminal(() {});
      terminal.activate();

      expect(terminal.snapshot.data, 25);
      expect(controller.coral.isActivated, isTrue);
      expect(convergedCoral.isActivated, isTrue);

      terminal.deactivate();
      expect(terminal.isDeactivated, isTrue);
      expect(controller.coral.isDeactivated, isTrue);
    });

    test('Coupler-to-Coupler Hotswap transfer with seal: false successfully transfers ownership', () {
      final node = CoralController<int>(10).coral;

      final couplerA = CoralCoupler<int>(node, seal: false, hotswap: true);
      final couplerB = CoralCoupler<int>.late(seal: true, hotswap: true);

      final termA = couplerA.toTerminal(() {});
      final termB = couplerB.toTerminal(() {});
      termA.activate();
      termB.activate();

      expect(couplerA.snapshot.data, 10);

      // Swapping node from detachable Coupler A to Coupler B
      couplerB.couple(node);

      expect(couplerB.snapshot.data, 10);
      expect(couplerA.snapshot.isEmpty, isTrue, reason: 'Node was detached from Coupler A');

      termA.deactivate();
      termB.deactivate();
    });

    test('Coupler-to-Coupler Hotswap transfer with seal: true prevents stealing and sets damaged state', () {
      final node = CoralController<int>(10).coral;

      final couplerA = CoralCoupler<int>(node, seal: true, hotswap: true);
      final couplerB = CoralCoupler<int>.late(seal: true, hotswap: true);

      final termA = couplerA.toTerminal(() {});
      final termB = couplerB.toTerminal(() {});
      termA.activate();
      termB.activate();

      expect(couplerA.snapshot.data, 10);

      // Attempting to steal strongly owned node from sealed Coupler A into Coupler B
      couplerB.couple(node);

      expect(couplerB.snapshot.isDamaged, isTrue,
          reason: 'Stealing node from sealed coupler marks destination coupler damaged');
      expect(couplerA.snapshot.data, 10, reason: 'Original coupler retains ownership');

      termA.deactivate();
      termB.deactivate();
    });
  });
}
