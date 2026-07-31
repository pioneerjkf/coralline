// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('2. Data Flow & Computation Model (Push-Dirty, Pull-Data)', () {
    test('Dirty Notification triggers UI updates without computing data', () {
      int computationCount = 0;
      int dirtyCount = 0;

      final source = CoralController<int>(0);
      final cascaded = source.coral.cascade((data) {
        computationCount++;
        return Coral.data(data);
      }, eager: false);

      final terminal = cascaded.toTerminal(() {
        dirtyCount++;
      });
      terminal.activate();

      expect(computationCount, 0, reason: 'Initial activation should not trigger lazy computation');
      expect(dirtyCount, 0);

      // Update source multiple times
      source.set(1);
      source.set(2);
      source.set(3);

      expect(computationCount, 0, reason: 'Data computation must be delayed until .snapshot is called');
      expect(dirtyCount, 3, reason: 'Dirty notifications must trigger immediately for UI updates');

      // Now pull data
      expect(terminal.snapshot.dataOrNull, 3);
      expect(computationCount, 1, reason: 'Only the final pull triggers computation');

      terminal.deactivate();
    });

    test('Memoization (Caching): Repeated pulls without source changes return cached data', () {
      int computationCount = 0;

      final source = CoralController<int>(0);
      final cascaded = source.coral.cascade((data) {
        computationCount++;
        return Coral.data(data * 2);
      }, eager: false);

      final terminal = cascaded.toTerminal(() {});
      terminal.activate();

      expect(terminal.snapshot.dataOrNull, 0);
      expect(computationCount, 1);

      expect(terminal.snapshot.dataOrNull, 0);
      expect(terminal.snapshot.dataOrNull, 0);
      expect(computationCount, 1, reason: 'Repeated pulls without dirty signal must use cached snapshot');

      terminal.deactivate();
    });

    test('Lazy computation does not compute on activation', () {
      int callCount = 0;
      final source = Coral.data(10);

      final cascaded = source.cascade((data) {
        callCount++;
        return Coral.data(data * 2);
      }, eager: false);

      final terminal = cascaded.toTerminal(() {});
      terminal.activate();

      expect(callCount, 0, reason: 'Lazy computation should not compute upon activation');

      expect(cascaded.data, 20);
      expect(callCount, 1, reason: 'Lazy computation computes upon data access');

      terminal.deactivate();
    });

    test('Eager true computes upon activation', () {
      int callCount = 0;
      final source = Coral.data(10);

      final cascaded = source.cascade((data) {
        callCount++;
        return Coral.data(data * 2);
      }, eager: true);

      final terminal = cascaded.toTerminal(() {});
      terminal.activate();

      // Eager should call it immediately upon activation, without waiting for .data access.
      expect(callCount, 1, reason: 'Eager computation should compute upon activation');
      expect(cascaded.data, 20);
      expect(callCount, 1);

      terminal.deactivate();
    });

    test('diverge with eager false computes on data access', () {
      int callCount = 0;
      final source = Coral.data('a');

      final diverged = source.diverge((data) {
        callCount++;
        return [Coral.data('${data}1'), Coral.data('${data}2')];
      }, eager: false);

      final terminal = diverged.toTerminal(() {});
      terminal.activate();

      expect(callCount, 0);

      final data = diverged.lines.map((c) => c.data).toList();
      expect(data, ['a1', 'a2']);
      expect(callCount, 1);

      terminal.deactivate();
    });

    test('diverge with eager true computes on activation', () {
      int callCount = 0;
      final source = Coral.data('a');

      final diverged = source.diverge((data) {
        callCount++;
        return [Coral.data('${data}1'), Coral.data('${data}2')];
      }, eager: true);

      final terminal = diverged.toTerminal(() {});
      terminal.activate();

      expect(callCount, 1);

      final data = diverged.lines.map((c) => c.data).toList();
      expect(data, ['a1', 'a2']);
      expect(callCount, 1);

      terminal.deactivate();
    });

    test('converge with eager false computes on data access', () {
      int callCount = 0;
      final source = [Coral.data(1), Coral.data(2), Coral.data(3)].toTrunk();

      final converged = source.converge((lines) {
        callCount++;
        final sum = lines.fold<int>(0, (acc, coral) => acc + coral.data);
        return Coral.data(sum);
      }, eager: false);

      final terminal = converged.toTerminal(() {});
      terminal.activate();

      expect(callCount, 0);

      expect(converged.data, 6);
      expect(callCount, 1);

      terminal.deactivate();
    });

    test('converge with eager true computes on activation', () {
      int callCount = 0;
      final source = [Coral.data(1), Coral.data(2), Coral.data(3)].toTrunk();

      final converged = source.converge((lines) {
        callCount++;
        final sum = lines.fold<int>(0, (acc, coral) => acc + coral.data);
        return Coral.data(sum);
      }, eager: true);

      final terminal = converged.toTerminal(() {});
      terminal.activate();

      expect(callCount, 1);

      expect(converged.data, 6);
      expect(callCount, 1);

      terminal.deactivate();
    });

    test('Seal true prevents ownership stealing', () {
      final myCoral = Coral.data('precious');

      // seal: true
      final owner1 = Coral.data(1).cascade((_) => myCoral, seal: true, eager: false);
      final owner2 = Coral.data(2).cascade((_) => myCoral, seal: true, eager: false);

      final terminal1 = owner1.toTerminal(() {});
      terminal1.activate();

      expect(owner1.data, 'precious'); // owner1 claims myCoral

      final terminal2 = owner2.toTerminal(() {});
      terminal2.activate();

      // owner2 tries to claim myCoral, but owner1 has it sealed
      expect(() => owner2.data, throwsException);

      terminal1.deactivate();
      terminal2.deactivate();
    });

    test('Seal false allows ownership stealing', () {
      final myCoral = Coral.data('precious');

      // seal: false
      final owner1 = Coral.data(1).cascade((_) => myCoral, seal: false, eager: false);
      final owner2 = Coral.data(2).cascade((_) => myCoral, seal: false, eager: false);

      final terminal1 = owner1.toTerminal(() {});
      terminal1.activate();

      expect(owner1.data, 'precious'); // owner1 claims myCoral

      final terminal2 = owner2.toTerminal(() {});
      terminal2.activate();

      // owner2 successfully steals myCoral
      expect(owner2.data, 'precious');

      // owner1's inbound becomes empty
      expect(owner1.snapshot.isEmpty, isTrue);

      terminal1.deactivate();
      terminal2.deactivate();
    });

    test('Hotswap false (Coldswap) deactivates old node on swap', () {
      int disposeCount = 0;
      final source = CoralController<int>(1, broadcast: true);

      final cascaded = source.coral.cascade((data) {
        return Coral.resource(
          create: () => 'data_$data',
          dispose: (d) {
            disposeCount++;
          },
        );
      }, hotswap: false);

      final terminal = cascaded.toTerminal(() {});
      terminal.activate();

      expect(cascaded.data, 'data_1');
      expect(disposeCount, 0);

      // Update source to trigger a swap
      source.set(2);

      expect(cascaded.data, 'data_2');
      expect(disposeCount, 1, reason: 'Old node should be disposed (deactivated) immediately on Coldswap');

      terminal.deactivate();
    });

    test('Hotswap true (Hotswap) preserves old node on swap', () async {
      int disposeCount = 0;
      final source = CoralController<int>(1, broadcast: true);

      final cascaded = source.coral.cascade((data) {
        return Coral.resource(
          create: () => 'data_$data',
          dispose: (d) {
            disposeCount++;
          },
        );
      }, hotswap: true);

      final terminal = cascaded.toTerminal(() {});
      terminal.activate();

      expect(cascaded.data, 'data_1');
      expect(disposeCount, 0);

      // Update source to trigger a swap
      source.set(2);

      expect(cascaded.data, 'data_2');
      expect(disposeCount, 0, reason: 'Old node should NOT be disposed (deactivated) immediately on Hotswap');

      // Await microtask queue to allow mooring point to flush
      await Future.microtask(() {});

      expect(disposeCount, 1, reason: 'Old node should be disposed after microtask completes');

      terminal.deactivate();
      expect(disposeCount, 2, reason: 'New node should be disposed when pipeline is deactivated');
    });

    test('Dirty Notification Wave Collapsing across multi-path upstream topology', () {
      final source = CoralController<int>(10);
      int dirtyCount = 0;

      final diverged = source.coral.diverge((val) {
        return [
          Coral.data(val * 2),
          Coral.data(val + 5),
        ];
      });

      final converged = diverged.converge((lines) {
        final list = lines.toList();
        return Coral.data(list[0].data + list[1].data);
      });

      final terminal = converged.toTerminal(() {
        dirtyCount++;
      });
      terminal.activate();

      // Initial pull establishes pipeline joints
      expect(terminal.data, 35); // 20 + 15 = 35
      expect(dirtyCount, 0);

      // Trigger update on source
      source.set(20);

      // Even though there are 2 diverged paths, dirty notification should collapse into 1 dirty call
      expect(dirtyCount, 1, reason: 'Dirty notifications from multiple upstream paths should collapse');

      terminal.deactivate();
    });

    test('Bursty Mutation Coalescing maintains O(1) lazy computation', () {
      int computationCount = 0;
      int dirtyCount = 0;

      final source = CoralController<int>(0);
      final cascaded = source.coral.cascade((data) {
        computationCount++;
        return Coral.data(data * 10);
      }, eager: false);

      final terminal = cascaded.toTerminal(() {
        dirtyCount++;
      });
      terminal.activate();

      expect(computationCount, 0);
      expect(dirtyCount, 0);

      // Execute 1,000 rapid synchronous updates
      for (int i = 1; i <= 1000; i++) {
        source.set(i);
      }

      expect(dirtyCount, 1000);
      expect(computationCount, 0, reason: 'Data computation must stay at 0 regardless of bursty mutation count');

      // Now pull final value
      expect(terminal.snapshot.dataOrNull, 10000);
      expect(computationCount, 1, reason: 'Computation must occur exactly once on pull (O(1))');

      terminal.deactivate();
    });

    test('Seal false ownership stealing produces fail-fast exception and recovers with fallback', () {
      final sharedCoral = Coral.data('sensitive_payload');

      final owner1 = Coral.data(1)
          .cascade((_) => sharedCoral, seal: false, eager: false)
          .fallback(onEmpty: () => 'recovered_fallback');

      final owner2 = Coral.data(2).cascade((_) => sharedCoral, seal: false, eager: false);

      final terminal1 = owner1.toTerminal(() {});
      terminal1.activate();

      // Owner 1 claims sharedCoral
      expect(owner1.data, 'sensitive_payload');

      final terminal2 = owner2.toTerminal(() {});
      terminal2.activate();

      // Owner 2 steals sharedCoral
      expect(owner2.data, 'sensitive_payload');

      // Owner 1's inbound was stolen (becomes empty) -> fallback onEmpty catches it safely
      expect(owner1.data, 'recovered_fallback');

      terminal1.deactivate();
      terminal2.deactivate();
    });

    test('Dirty notification exception delegation to CorallineTerminalIntent', () {
      final source = CoralController<int>(5);
      Object? capturedError;

      final pipeline = source.coral.map((val) => val * 2);
      final faultyTerminal = CoralTerminal.withIntent(
        pipeline,
        intent: _TestTrackingIntent((err) => capturedError = err),
        onDirty: () {
          throw StateError('Simulated UI rendering crash during dirty dispatch');
        },
      );

      faultyTerminal.activate();

      // Update source -> dirty listener throws StateError, delegated to intent
      source.set(10);

      expect(capturedError, isA<StateError>());
      expect(faultyTerminal.data, 20);

      faultyTerminal.deactivate();
    });

    test('Dynamic short-circuit computation prevents computation of unread branches', () {
      final conditionController = CoralController<bool>(true);
      final branchAController = CoralController<int>(10);
      final branchBController = CoralController<int>(20);

      int branchAComputeCalls = 0;
      int branchBComputeCalls = 0;

      final branchA = branchAController.coral.map((v) {
        branchAComputeCalls++;
        return v * 2;
      });

      final branchB = branchBController.coral.map((v) {
        branchBComputeCalls++;
        return v * 3;
      });

      // Conditional switch pipeline
      final conditionalPipeline = conditionController.coral.cascade((useA) {
        return useA ? branchA : branchB;
      }, eager: false);

      final terminal = conditionalPipeline.toTerminal(() {});
      terminal.activate();

      expect(terminal.data, 20); // 10 * 2
      expect(branchAComputeCalls, 1);
      expect(branchBComputeCalls, 0);

      // Mutate unread branchB source
      branchBController.set(999);

      // Re-read terminal while condition is still true
      expect(terminal.data, 20);
      expect(branchBComputeCalls, 0, reason: 'Unread branchB should short-circuit and not compute');

      // Switch condition to false
      conditionController.set(false);

      // Now branchB is active
      expect(terminal.data, 2997); // 999 * 3
      expect(branchBComputeCalls, 1);

      terminal.deactivate();
    });
  });
}

final class _TestTrackingIntent extends CorallineTerminalIntent {
  _TestTrackingIntent(this.onError);
  final void Function(Object error) onError;

  @override
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    onError(error);
  }
}
