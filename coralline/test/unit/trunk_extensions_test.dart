// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

class MockTrunkProvider<T> implements TrunkProvider<T> {
  @override
  final Trunk<T> trunk;

  MockTrunkProvider(this.trunk);

  @override
  bool get isActivated => trunk.isActivated;

  @override
  bool get isDeactivated => trunk.isDeactivated;

  @override
  bool get isPaused => trunk.isPaused;

  @override
  bool get isRunning => trunk.isRunning;
}

void main() {
  group('Trunk Extensions Comprehensive Tests', () {
    group('TrunkComputationExtension Tests (aggregate, combine, converge)', () {
      test('aggregate reduces trunk lines into a single Coral scalar', () {
        final c1 = Coral.data(10);
        final c2 = Coral.data(20);
        final c3 = Coral.data(30);
        final trunk = [c1, c2, c3].toTrunk();

        final aggregated = trunk.aggregate((lines) => lines.fold<int>(0, (sum, line) => sum + line.data));
        final terminal = aggregated.toTerminal(() {});
        terminal.activate();

        expect(aggregated.data, 60);

        terminal.deactivate();
      });

      test('combine bundles all line data into Coral<List<T>>', () {
        final c1 = Coral.data('apple');
        final c2 = Coral.data('banana');
        final trunk = [c1, c2].toTrunk();

        final combined = trunk.combine();
        final terminal = combined.toTerminal(() {});
        terminal.activate();

        expect(combined.data, ['apple', 'banana']);

        terminal.deactivate();
      });

      test('aggregate allows full user-level control over line evaluation (partial aggregation & custom guarding)', () {
        final c1 = Coral.data(10);
        final c2 = Coral<int>.empty();
        final c3 = Coral.data(30);

        final trunk = [c1, c2, c3].toTrunk();

        // User can freely filter valid lines, perform partial aggregation, or inspect snapshots
        final partialSum = trunk.aggregate((lines) {
          return lines.where((l) => l.isValid).fold(0, (sum, l) => sum + l.data);
        });

        final term = partialSum.toTerminal(() {});
        term.activate();
        expect(partialSum.data, 40); // 10 + 30 (ignoring empty line 2!)
        term.deactivate();
      });

      test('converge 8 switch combinations (seal x hotswap x eager)', () {
        final trunk = [Coral.data(1)].toTrunk();

        final c1 = trunk.converge((lines) => Coral.data('1'), seal: true, hotswap: true, eager: true);
        final c2 = trunk.converge((lines) => Coral.data('2'), seal: true, hotswap: true, eager: false);
        final c3 = trunk.converge((lines) => Coral.data('3'), seal: true, hotswap: false, eager: true);
        final c4 = trunk.converge((lines) => Coral.data('4'), seal: true, hotswap: false, eager: false);
        final c5 = trunk.converge((lines) => Coral.data('5'), seal: false, hotswap: true, eager: true);
        final c6 = trunk.converge((lines) => Coral.data('6'), seal: false, hotswap: true, eager: false);
        final c7 = trunk.converge((lines) => Coral.data('7'), seal: false, hotswap: false, eager: true);
        final c8 = trunk.converge((lines) => Coral.data('8'), seal: false, hotswap: false, eager: false);

        expect(c1.runtimeType.toString(), contains('_SealedHotswapEagerConvergingCoral'));
        expect(c2.runtimeType.toString(), contains('_SealedHotswapLazyConvergingCoral'));
        expect(c3.runtimeType.toString(), contains('_SealedColdswapEagerConvergingCoral'));
        expect(c4.runtimeType.toString(), contains('_SealedColdswapLazyConvergingCoral'));
        expect(c5.runtimeType.toString(), contains('_DetachableHotswapEagerConvergingCoral'));
        expect(c6.runtimeType.toString(), contains('_DetachableHotswapLazyConvergingCoral'));
        expect(c7.runtimeType.toString(), contains('_DetachableColdswapEagerConvergingCoral'));
        expect(c8.runtimeType.toString(), contains('_DetachableColdswapLazyConvergingCoral'));

        final term = c1.toTerminal(() {});
        term.activate();
        expect(c1.data, '1');
        term.deactivate();
      });
    });

    group('TrunkProvider & TrunkProviderComputationExtension Tests', () {
      test('TrunkProvider forwards toTerminal', () {
        final trunk = [Coral.data(100)].toTrunk();
        final provider = MockTrunkProvider(trunk);

        final term = provider.toTerminal(() {});
        term.activate();
        expect(provider.trunk.lines.first.data, 100);
        term.deactivate();
      });

      test('TrunkProvider forwards aggregate', () {
        final trunk = [Coral.data(100), Coral.data(200)].toTrunk();
        final provider = MockTrunkProvider(trunk);

        final agg = provider.aggregate((lines) => lines.length);
        final aggTerm = agg.toTerminal(() {});
        aggTerm.activate();
        expect(agg.data, 2);
        aggTerm.deactivate();
      });

      test('TrunkProvider forwards combine', () {
        final trunk = [Coral.data(100), Coral.data(200)].toTrunk();
        final provider = MockTrunkProvider(trunk);

        final comb = provider.combine();
        final combTerm = comb.toTerminal(() {});
        combTerm.activate();
        expect(comb.data, [100, 200]);
        combTerm.deactivate();
      });

      test('TrunkProvider forwards converge', () {
        final trunk = [Coral.data(100)].toTrunk();
        final provider = MockTrunkProvider(trunk);

        final conv = provider.converge((lines) => Coral.data('provider_converged'));
        final convTerm = conv.toTerminal(() {});
        convTerm.activate();
        expect(conv.data, 'provider_converged');
        convTerm.deactivate();
      });
    });
  });
}
