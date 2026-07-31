// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('Pipeline Integration Tests', () {
    test('Scenario 1: Linear Pipeline (map -> distinct -> guard -> fallback)', () {
      final controller = CoralController<int>(1, distinct: false);

      int mapCalls = 0;
      final pipeline = controller.coral
          .map((val) {
            mapCalls++;
            return val * 2;
          })
          .distinct()
          .guard(canProceed: () => true)
          .fallback(onEmpty: () => -1);

      final terminal = pipeline.toTerminal(() {});
      terminal.activate();

      // Verify lazy computation: map is not called yet
      expect(mapCalls, 0);

      // Verify initial pull
      expect(terminal.data, 2);
      expect(mapCalls, 1);

      // Verify cache hit
      expect(terminal.data, 2);
      expect(mapCalls, 1);

      // Set same value -> distinct should prevent map or downstream push if identical
      controller.set(1);
      expect(terminal.data, 2);
      // distinct computes inbound to check if it changed.
      // Since controller changed (even if value is same, controller invalidates), distinct pulls inbound.
      // So map is called again.
      expect(mapCalls, 2);

      // Set new value
      controller.set(2);
      expect(terminal.data, 4);
      expect(mapCalls, 3);

      terminal.deactivate();
    });

    test('Scenario 2: Diverge and Converge Pipeline (Coral -> diverge -> Trunk -> converge -> Coral)', () {
      final controller = CoralController<int>(5);

      final diverged = controller.coral.diverge((data) {
        return [
          Coral.data(data * 1),
          Coral.data(data * 2),
          Coral.data(data * 3),
        ];
      });

      final converged = diverged.converge((lines) {
        final sum = lines.fold<int>(0, (acc, coral) => acc + coral.data);
        return Coral.data(sum);
      });

      final terminal = converged.toTerminal(() {});
      terminal.activate();

      // 5*1 + 5*2 + 5*3 = 30
      expect(terminal.data, 30);

      // Update source
      controller.set(10);
      // 10*1 + 10*2 + 10*3 = 60
      expect(terminal.data, 60);

      terminal.deactivate();
    });

    test('Scenario 3: Error Isolation & Recovery in Pipelines', () {
      final controller = CoralController<int>(10);

      final pipeline = controller.coral.map((val) {
        if (val == 0) throw ArgumentError('Value cannot be zero');
        return 100 ~/ val;
      }).fallback(onDamage: (error, [stack]) => 999);

      final terminal = pipeline.toTerminal(() {});
      terminal.activate();

      // Valid path
      expect(terminal.data, 10);

      // Error path (division by zero or user throw)
      controller.set(0);
      expect(terminal.data, 999, reason: 'Pipeline should recover using fallback on damage');

      terminal.deactivate();
    });

    test('Scenario 4: Dynamic Hot-swapping in Pipelines using Coupler', () {
      final c1 = Coral.data('A');
      final c2 = Coral.resource(
        create: () => 'B',
        dispose: (_) {},
      );

      final coupler = CoralCoupler<String>(c1, hotswap: true);
      final terminal = coupler.coral.toTerminal(() {});
      terminal.activate();

      expect(terminal.data, 'A');

      // Swap to c2
      final old = coupler.couple(c2);
      expect(old, c1);
      expect(terminal.data, 'B');

      // Detach and clean up
      terminal.deactivate();
    });

    test('Scenario 5: Diamond Topology & Glitch-Free Computation', () {
      final controller = CoralController<int>(5);

      int divergeCalls = 0;

      final diverged = controller.coral.diverge((val) {
        divergeCalls++;
        return [
          Coral.data(val * 2),
          Coral.data(val + 10),
        ];
      });

      final converged = diverged.converge((lines) {
        final list = lines.toList();
        final a = list[0].data;
        final b = list[1].data;
        return Coral.data(a + b);
      });

      final terminal = converged.toTerminal(() {});
      terminal.activate();

      // Initial pull: (5 * 2) + (5 + 10) = 10 + 15 = 25
      expect(terminal.data, 25);
      expect(divergeCalls, 1);

      // Trigger update on source
      controller.set(10);

      // (10 * 2) + (10 + 10) = 20 + 20 = 40
      expect(terminal.data, 40);
      expect(divergeCalls, 2);

      terminal.deactivate();
    });

    test('Scenario 6: Cascading Couplers with Resource Disposal Order', () async {
      bool disposed1 = false;
      bool disposed2 = false;

      final res1 = Coral.resource(
        create: () => 'Resource 1',
        dispose: (_) => disposed1 = true,
      );

      final res2 = Coral.resource(
        create: () => 'Resource 2',
        dispose: (_) => disposed2 = true,
      );

      final couplerUpper = CoralCoupler<String>(res1, hotswap: true);
      final couplerLower = CoralCoupler<String>(couplerUpper.coral, hotswap: true);

      final terminal = couplerLower.coral.toTerminal(() {});
      terminal.activate();

      expect(terminal.data, 'Resource 1');
      expect(disposed1, false);

      // Swap upper coupler to res2
      couplerUpper.couple(res2);
      expect(terminal.data, 'Resource 2');
      expect(disposed1, false, reason: 'Old resource disposal is deferred to microtask');

      await Future.microtask(() {});
      expect(disposed1, true, reason: 'Old resource disposed after microtask flush');
      expect(disposed2, false);

      // Deactivate terminal -> should dispose current resource
      terminal.deactivate();
      expect(disposed2, true, reason: 'Current resource must be disposed on terminal deactivate');
    });

    test('Scenario 7: Inactive State & Re-activation Cleanliness', () {
      final controller = CoralController<int>(100);

      int mapCalls = 0;
      final pipeline = controller.coral.map((v) {
        mapCalls++;
        return v * 3;
      });

      final terminal = pipeline.toTerminal(() {});
      terminal.activate();

      expect(terminal.data, 300);
      expect(mapCalls, 1);

      // Deactivate terminal
      terminal.deactivate();

      // Mutate controller while terminal is inactive
      controller.set(200);
      controller.set(300);
      controller.set(400);

      // Map should not be called while inactive (lazy maintenance)
      expect(mapCalls, 1);

      // Re-activate terminal
      terminal.activate();

      // Should pull fresh data immediately without stale cache
      expect(terminal.data, 1200);
      expect(mapCalls, 2);

      terminal.deactivate();
    });

    test('Scenario 8: Partial Branch Error Isolation in Diverged Pipelines', () {
      final controller = CoralController<int>(10);

      final diverged = controller.coral.diverge((val) {
        return [
          // Normal branch
          Coral.data(val * 2),
          // Error prone branch protected by fallback
          Coral.data(val).map((v) {
            if (v == 0) throw StateError('Division by zero hazard');
            return 100 ~/ v;
          }).fallback(onDamage: (err, [st]) => -999),
        ];
      });

      final converged = diverged.converge((lines) {
        final list = lines.toList();
        final val1 = list[0].data;
        final val2 = list[1].data;
        return Coral.data(val1 + val2);
      });

      final terminal = converged.toTerminal(() {});
      terminal.activate();

      // Normal state: 10*2 + 100~/10 = 20 + 10 = 30
      expect(terminal.data, 30);

      // Trigger error in branch 2
      controller.set(0);

      // Branch 1: 0*2 = 0, Branch 2: fallback -999 => Total: -999
      expect(terminal.data, -999, reason: 'Erroneous branch should fallback safely without breaking healthy branch');

      // Recover to valid state
      controller.set(5);
      // Branch 1: 5*2 = 10, Branch 2: 100~/5 = 20 => Total: 30
      expect(terminal.data, 30);

      terminal.deactivate();
    });
  });
}
