// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('Hotswap Cascading Classes Comprehensive Tests', () {
    group('Coral.cascade Hotswap variants', () {
      test('_SealedHotswapLazyCascadingCoral (seal: true, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final cascaded = source.coral.cascade((data) {
          return Coral.resource(
            create: () => 'data_$data',
            dispose: (_) => disposeCount++,
          );
        }, seal: true, hotswap: true, eager: false);

        expect(cascaded.runtimeType.toString(), contains('_SealedHotswapLazyCascadingCoral'));

        final terminal = cascaded.toTerminal(() {});
        terminal.activate();

        expect(cascaded.data, 'data_1');
        expect(disposeCount, 0);

        source.set(2);
        expect(cascaded.data, 'data_2');
        expect(disposeCount, 0, reason: 'Hotswap preserves old node until microtask flushes');

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_SealedHotswapEagerCascadingCoral (seal: true, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final cascaded = source.coral.cascade((data) {
          computeCount++;
          return Coral.resource(
            create: () => 'data_$data',
            dispose: (_) => disposeCount++,
          );
        }, seal: true, hotswap: true, eager: true);

        expect(cascaded.runtimeType.toString(), contains('_SealedHotswapEagerCascadingCoral'));

        final terminal = cascaded.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1), reason: 'Eager computes upon activation');
        expect(cascaded.data, 'data_1');

        final prevComputeCount = computeCount;
        source.set(2);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1, reason: 'Eager computes upon dirty signal');
        expect(cascaded.data, 'data_2');

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_DetachableHotswapLazyCascadingCoral (seal: false, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final cascaded = source.coral.cascade((data) {
          return Coral.resource(
            create: () => 'data_$data',
            dispose: (_) => disposeCount++,
          );
        }, seal: false, hotswap: true, eager: false);

        expect(cascaded.runtimeType.toString(), contains('_DetachableHotswapLazyCascadingCoral'));

        final terminal = cascaded.toTerminal(() {});
        terminal.activate();

        expect(cascaded.data, 'data_1');
        expect(disposeCount, 0);

        source.set(2);
        expect(cascaded.data, 'data_2');
        expect(disposeCount, 0);

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_DetachableHotswapEagerCascadingCoral (seal: false, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final cascaded = source.coral.cascade((data) {
          computeCount++;
          return Coral.resource(
            create: () => 'data_$data',
            dispose: (_) => disposeCount++,
          );
        }, seal: false, hotswap: true, eager: true);

        expect(cascaded.runtimeType.toString(), contains('_DetachableHotswapEagerCascadingCoral'));

        final terminal = cascaded.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1));
        expect(cascaded.data, 'data_1');

        final prevComputeCount = computeCount;
        source.set(2);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1);
        expect(cascaded.data, 'data_2');

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });
    });

    group('Trunk.converge Hotswap variants', () {
      test('_SealedHotswapLazyConvergingCoral (seal: true, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source1 = CoralController<int>(1, broadcast: true);
        final source2 = CoralController<int>(2, broadcast: true);
        final trunk = [source1.coral, source2.coral].toTrunk();

        final converged = trunk.converge((lines) {
          final sum = lines.fold<int>(0, (acc, c) => acc + c.data);
          return Coral.resource(
            create: () => 'sum_$sum',
            dispose: (_) => disposeCount++,
          );
        }, seal: true, hotswap: true, eager: false);

        expect(converged.runtimeType.toString(), contains('_SealedHotswapLazyConvergingCoral'));

        final terminal = converged.toTerminal(() {});
        terminal.activate();

        expect(converged.data, 'sum_3');
        expect(disposeCount, 0);

        source1.set(10);
        expect(converged.data, 'sum_12');
        expect(disposeCount, 0);

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_SealedHotswapEagerConvergingCoral (seal: true, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source1 = CoralController<int>(1, broadcast: true);
        final source2 = CoralController<int>(2, broadcast: true);
        final trunk = [source1.coral, source2.coral].toTrunk();

        final converged = trunk.converge((lines) {
          computeCount++;
          final sum = lines.fold<int>(0, (acc, c) => acc + c.data);
          return Coral.resource(
            create: () => 'sum_$sum',
            dispose: (_) => disposeCount++,
          );
        }, seal: true, hotswap: true, eager: true);

        expect(converged.runtimeType.toString(), contains('_SealedHotswapEagerConvergingCoral'));

        final terminal = converged.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1));
        expect(converged.data, 'sum_3');

        final prevComputeCount = computeCount;
        source1.set(10);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1);
        expect(converged.data, 'sum_12');

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_DetachableHotswapLazyConvergingCoral (seal: false, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source1 = CoralController<int>(1, broadcast: true);
        final source2 = CoralController<int>(2, broadcast: true);
        final trunk = [source1.coral, source2.coral].toTrunk();

        final converged = trunk.converge((lines) {
          final sum = lines.fold<int>(0, (acc, c) => acc + c.data);
          return Coral.resource(
            create: () => 'sum_$sum',
            dispose: (_) => disposeCount++,
          );
        }, seal: false, hotswap: true, eager: false);

        expect(converged.runtimeType.toString(), contains('_DetachableHotswapLazyConvergingCoral'));

        final terminal = converged.toTerminal(() {});
        terminal.activate();

        expect(converged.data, 'sum_3');
        expect(disposeCount, 0);

        source1.set(10);
        expect(converged.data, 'sum_12');
        expect(disposeCount, 0);

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('_DetachableHotswapEagerConvergingCoral (seal: false, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source1 = CoralController<int>(1, broadcast: true);
        final source2 = CoralController<int>(2, broadcast: true);
        final trunk = [source1.coral, source2.coral].toTrunk();

        final converged = trunk.converge((lines) {
          computeCount++;
          final sum = lines.fold<int>(0, (acc, c) => acc + c.data);
          return Coral.resource(
            create: () => 'sum_$sum',
            dispose: (_) => disposeCount++,
          );
        }, seal: false, hotswap: true, eager: true);

        expect(converged.runtimeType.toString(), contains('_DetachableHotswapEagerConvergingCoral'));

        final terminal = converged.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1));
        expect(converged.data, 'sum_3');

        final prevComputeCount = computeCount;
        source1.set(10);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1);
        expect(converged.data, 'sum_12');

        await Future.microtask(() {});
        expect(disposeCount, 1);

        terminal.deactivate();
        expect(disposeCount, 2);
      });
    });

    group('Coral.diverge Hotswap variants', () {
      test('_SealedHotswapLazyDivergingTrunk (seal: true, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final diverged = source.coral.diverge((data) {
          return [
            Coral.resource(
              create: () => 'item_${data}_a',
              dispose: (_) => disposeCount++,
            ),
            Coral.resource(
              create: () => 'item_${data}_b',
              dispose: (_) => disposeCount++,
            ),
          ];
        }, seal: true, hotswap: true, eager: false);

        expect(diverged.runtimeType.toString(), contains('_SealedHotswapLazyDivergingTrunk'));

        final terminal = diverged.toTerminal(() {});
        terminal.activate();

        final lines1 = diverged.lines.map((c) => c.data).toList();
        expect(lines1, ['item_1_a', 'item_1_b']);
        expect(disposeCount, 0);

        source.set(2);
        final lines2 = diverged.lines.map((c) => c.data).toList();
        expect(lines2, ['item_2_a', 'item_2_b']);
        expect(disposeCount, 0);

        await Future.microtask(() {});
        expect(disposeCount, 2);

        terminal.deactivate();
        expect(disposeCount, 4);
      });

      test('_SealedHotswapEagerDivergingTrunk (seal: true, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final diverged = source.coral.diverge((data) {
          computeCount++;
          return [
            Coral.resource(
              create: () => 'item_${data}_a',
              dispose: (_) => disposeCount++,
            ),
            Coral.resource(
              create: () => 'item_${data}_b',
              dispose: (_) => disposeCount++,
            ),
          ];
        }, seal: true, hotswap: true, eager: true);

        expect(diverged.runtimeType.toString(), contains('_SealedHotswapEagerDivergingTrunk'));

        final terminal = diverged.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1));
        final lines1 = diverged.lines.map((c) => c.data).toList();
        expect(lines1, ['item_1_a', 'item_1_b']);

        final prevComputeCount = computeCount;
        source.set(2);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1);
        final lines2 = diverged.lines.map((c) => c.data).toList();
        expect(lines2, ['item_2_a', 'item_2_b']);

        await Future.microtask(() {});
        expect(disposeCount, 2);

        terminal.deactivate();
        expect(disposeCount, 4);
      });

      test('_DetachableHotswapLazyDivergingTrunk (seal: false, hotswap: true, eager: false)', () async {
        int disposeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final diverged = source.coral.diverge((data) {
          return [
            Coral.resource(
              create: () => 'item_${data}_a',
              dispose: (_) => disposeCount++,
            ),
            Coral.resource(
              create: () => 'item_${data}_b',
              dispose: (_) => disposeCount++,
            ),
          ];
        }, seal: false, hotswap: true, eager: false);

        expect(diverged.runtimeType.toString(), contains('_DetachableHotswapLazyDivergingTrunk'));

        final terminal = diverged.toTerminal(() {});
        terminal.activate();

        final lines1 = diverged.lines.map((c) => c.data).toList();
        expect(lines1, ['item_1_a', 'item_1_b']);
        expect(disposeCount, 0);

        source.set(2);
        final lines2 = diverged.lines.map((c) => c.data).toList();
        expect(lines2, ['item_2_a', 'item_2_b']);
        expect(disposeCount, 0);

        await Future.microtask(() {});
        expect(disposeCount, 2);

        terminal.deactivate();
        expect(disposeCount, 4);
      });

      test('_DetachableHotswapEagerDivergingTrunk (seal: false, hotswap: true, eager: true)', () async {
        int disposeCount = 0;
        int computeCount = 0;
        final source = CoralController<int>(1, broadcast: true);

        final diverged = source.coral.diverge((data) {
          computeCount++;
          return [
            Coral.resource(
              create: () => 'item_${data}_a',
              dispose: (_) => disposeCount++,
            ),
            Coral.resource(
              create: () => 'item_${data}_b',
              dispose: (_) => disposeCount++,
            ),
          ];
        }, seal: false, hotswap: true, eager: true);

        expect(diverged.runtimeType.toString(), contains('_DetachableHotswapEagerDivergingTrunk'));

        final terminal = diverged.toTerminal(() {});
        terminal.activate();

        expect(computeCount, greaterThanOrEqualTo(1));
        final lines1 = diverged.lines.map((c) => c.data).toList();
        expect(lines1, ['item_1_a', 'item_1_b']);

        final prevComputeCount = computeCount;
        source.set(2);
        await Future.microtask(() {});
        expect(computeCount, prevComputeCount + 1);
        final lines2 = diverged.lines.map((c) => c.data).toList();
        expect(lines2, ['item_2_a', 'item_2_b']);

        await Future.microtask(() {});
        expect(disposeCount, 2);

        terminal.deactivate();
        expect(disposeCount, 4);
      });
    });
  });
}
