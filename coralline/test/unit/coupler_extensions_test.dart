// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('CoralCoupler & TrunkCoupler Extensions Comprehensive Tests', () {
    group('CoralCoupler Extensions Tests', () {
      test('CoralCoupler forwards CoralProviderExtension methods (toTerminal, toBroadcaster)', () {
        final coupler1 = CoralCoupler<String>(Coral.data('coupler_data_1'));
        final coupler2 = CoralCoupler<String>(Coral.data('coupler_data_2'));

        // 1. toTerminal direct extension call on CoralCoupler
        int dirtyCount = 0;
        final terminal = coupler1.toTerminal(() => dirtyCount++);
        terminal.activate();

        expect(terminal.snapshot.data, 'coupler_data_1');

        // 2. toBroadcaster direct extension call on CoralCoupler
        final broadcaster = coupler2.toBroadcaster();
        final broadTerminal = broadcaster.toTerminal(() {});
        broadTerminal.activate();

        expect(broadTerminal.snapshot.data, 'coupler_data_2');

        broadTerminal.deactivate();
        terminal.deactivate();
      });

      test('CoralCoupler forwards CoralProviderComputationExtension methods (map, cascade, distinct, fallback, guard)',
          () {
        final cMap = CoralCoupler<int>(Coral.data(10)).map((v) => 'val_$v');
        final cCascade = CoralCoupler<int>(Coral.data(10)).cascade((v) => Coral.data(v * 2));
        final cDistinct = CoralCoupler<int>(Coral.data(10)).distinct();
        final cGuard = CoralCoupler<int>(Coral.data(10)).guard(canProceed: () => true);
        final cFallback = CoralCoupler<int>(Coral.data(10)).fallback(onEmpty: () => 0);

        final tMapped = cMap.toTerminal(() {});
        final tCascaded = cCascade.toTerminal(() {});
        final tDistinct = cDistinct.toTerminal(() {});
        final tGuarded = cGuard.toTerminal(() {});
        final tFallbacked = cFallback.toTerminal(() {});

        tMapped.activate();
        tCascaded.activate();
        tDistinct.activate();
        tGuarded.activate();
        tFallbacked.activate();

        expect(cMap.data, 'val_10');
        expect(cCascade.data, 20);
        expect(cDistinct.data, 10);
        expect(cGuard.data, 10);
        expect(cFallback.data, 10);

        tMapped.deactivate();
        tCascaded.deactivate();
        tDistinct.deactivate();
        tGuarded.deactivate();
        tFallbacked.deactivate();
      });

      test('CoralCouplerDebugExtension properties and trace on CoralCoupler', () {
        final coupler = CoralCoupler<int>(Coral.data(42));
        coupler.debugTrace('coupler_test');

        expect(coupler.debugTag, 'coupler_test');
        expect(coupler.debugCreationLocation, isNotNull);
      });
    });

    group('TrunkCoupler Extensions Tests', () {
      test('TrunkCoupler forwards TrunkProviderExtension methods (toTerminal)', () {
        final coupler = TrunkCoupler<String>([Coral.data('t_data')].toTrunk());

        final terminal = coupler.toTerminal(() {});
        terminal.activate();

        expect(terminal.snapshot.lines.first.data, 't_data');
        terminal.deactivate();
      });

      test('TrunkCoupler forwards TrunkProviderComputationExtension methods (aggregate, combine, converge)', () {
        // 1. aggregate on TrunkCoupler
        final couplerAgg = TrunkCoupler<int>([Coral.data(10), Coral.data(20)].toTrunk());
        final aggregated = couplerAgg.aggregate((lines) => lines.fold<int>(0, (sum, l) => sum + l.data));
        final aggTerminal = aggregated.toTerminal(() {});
        aggTerminal.activate();

        expect(aggregated.data, 30);
        aggTerminal.deactivate();

        // 2. combine on TrunkCoupler
        final couplerComb = TrunkCoupler<int>([Coral.data(10), Coral.data(20)].toTrunk());
        final combined = couplerComb.combine();
        final combTerminal = combined.toTerminal(() {});
        combTerminal.activate();

        expect(combined.data, [10, 20]);
        combTerminal.deactivate();

        // 3. converge on TrunkCoupler
        final couplerConv = TrunkCoupler<int>([Coral.data(10), Coral.data(20)].toTrunk());
        final converged = couplerConv.converge((lines) => Coral.data('converged_${lines.length}'));
        final convTerminal = converged.toTerminal(() {});
        convTerminal.activate();

        expect(converged.data, 'converged_2');
        convTerminal.deactivate();
      });
    });
  });
}
