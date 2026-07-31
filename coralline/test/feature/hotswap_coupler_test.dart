// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('Hotswap Coupler Proxy Comprehensive Tests', () {
    group('CoralCoupler Hotswap Variants', () {
      test('_SealedHotswapCoralProxy (seal: true, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final c1 = Coral.resource(
          create: () => 'resource_1',
          dispose: (_) => disposeCount1++,
        );

        final c2 = Coral.resource(
          create: () => 'resource_2',
          dispose: (_) => disposeCount2++,
        );

        final coupler = CoralCoupler<String>(c1, seal: true, hotswap: true);
        expect(coupler.coral.runtimeType.toString(), contains('_SealedHotswapCoralProxy'));

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        expect(coupler.coral.data, 'resource_1');
        expect(disposeCount1, 0);

        // Couple c2
        coupler.couple(c2);
        expect(coupler.coral.data, 'resource_2');
        expect(disposeCount1, 0, reason: 'Old resource c1 should not be disposed immediately on Hotswap');

        await Future.microtask(() {});
        expect(disposeCount1, 1, reason: 'Old resource c1 disposed after microtask flush');
        expect(disposeCount2, 0);

        terminal.deactivate();
        expect(disposeCount2, 1, reason: 'Current resource c2 disposed on pipeline deactivation');
      });

      test('_SealedHotswapCoralProxy.late (seal: true, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final c1 = Coral.resource(
          create: () => 'resource_1',
          dispose: (_) => disposeCount1++,
        );

        final c2 = Coral.resource(
          create: () => 'resource_2',
          dispose: (_) => disposeCount2++,
        );

        final coupler = CoralCoupler<String>.late(seal: true, hotswap: true);
        expect(coupler.coral.runtimeType.toString(), contains('_SealedHotswapCoralProxy'));

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        coupler.couple(c1);
        expect(coupler.coral.data, 'resource_1');

        coupler.couple(c2);
        expect(coupler.coral.data, 'resource_2');
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });

      test('_DetachableHotswapCoralProxy (seal: false, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final c1 = Coral.resource(
          create: () => 'resource_1',
          dispose: (_) => disposeCount1++,
        );

        final c2 = Coral.resource(
          create: () => 'resource_2',
          dispose: (_) => disposeCount2++,
        );

        final coupler = CoralCoupler<String>(c1, seal: false, hotswap: true);
        expect(coupler.coral.runtimeType.toString(), contains('_DetachableHotswapCoralProxy'));

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        expect(coupler.coral.data, 'resource_1');
        expect(disposeCount1, 0);

        coupler.couple(c2);
        expect(coupler.coral.data, 'resource_2');
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);
        expect(disposeCount2, 0);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });

      test('_DetachableHotswapCoralProxy.late (seal: false, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final c1 = Coral.resource(
          create: () => 'resource_1',
          dispose: (_) => disposeCount1++,
        );

        final c2 = Coral.resource(
          create: () => 'resource_2',
          dispose: (_) => disposeCount2++,
        );

        final coupler = CoralCoupler<String>.late(seal: false, hotswap: true);
        expect(coupler.coral.runtimeType.toString(), contains('_DetachableHotswapCoralProxy'));

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        coupler.couple(c1);
        expect(coupler.coral.data, 'resource_1');

        coupler.couple(c2);
        expect(coupler.coral.data, 'resource_2');
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });
    });

    group('TrunkCoupler Hotswap Variants', () {
      test('_SealedHotswapTrunkProxy (seal: true, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final t1 = [
          Coral.resource(
            create: () => 'trunk_1_a',
            dispose: (_) => disposeCount1++,
          )
        ].toTrunk();

        final t2 = [
          Coral.resource(
            create: () => 'trunk_2_a',
            dispose: (_) => disposeCount2++,
          )
        ].toTrunk();

        final coupler = TrunkCoupler<String>(t1, seal: true, hotswap: true);
        expect(coupler.trunk.runtimeType.toString(), contains('_SealedHotswapTrunkProxy'));

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        final lines1 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines1, ['trunk_1_a']);
        expect(disposeCount1, 0);

        coupler.couple(t2);
        final lines2 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines2, ['trunk_2_a']);
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);
        expect(disposeCount2, 0);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });

      test('_SealedHotswapTrunkProxy.late (seal: true, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final t1 = [
          Coral.resource(
            create: () => 'trunk_1_a',
            dispose: (_) => disposeCount1++,
          )
        ].toTrunk();

        final t2 = [
          Coral.resource(
            create: () => 'trunk_2_a',
            dispose: (_) => disposeCount2++,
          )
        ].toTrunk();

        final coupler = TrunkCoupler<String>.late(seal: true, hotswap: true);
        expect(coupler.trunk.runtimeType.toString(), contains('_SealedHotswapTrunkProxy'));

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        coupler.couple(t1);
        final lines1 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines1, ['trunk_1_a']);

        coupler.couple(t2);
        final lines2 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines2, ['trunk_2_a']);
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });

      test('_DetachableHotswapTrunkProxy (seal: false, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final t1 = [
          Coral.resource(
            create: () => 'trunk_1_a',
            dispose: (_) => disposeCount1++,
          )
        ].toTrunk();

        final t2 = [
          Coral.resource(
            create: () => 'trunk_2_a',
            dispose: (_) => disposeCount2++,
          )
        ].toTrunk();

        final coupler = TrunkCoupler<String>(t1, seal: false, hotswap: true);
        expect(coupler.trunk.runtimeType.toString(), contains('_DetachableHotswapTrunkProxy'));

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        final lines1 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines1, ['trunk_1_a']);
        expect(disposeCount1, 0);

        coupler.couple(t2);
        final lines2 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines2, ['trunk_2_a']);
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);
        expect(disposeCount2, 0);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });

      test('_DetachableHotswapTrunkProxy.late (seal: false, hotswap: true)', () async {
        int disposeCount1 = 0;
        int disposeCount2 = 0;

        final t1 = [
          Coral.resource(
            create: () => 'trunk_1_a',
            dispose: (_) => disposeCount1++,
          )
        ].toTrunk();

        final t2 = [
          Coral.resource(
            create: () => 'trunk_2_a',
            dispose: (_) => disposeCount2++,
          )
        ].toTrunk();

        final coupler = TrunkCoupler<String>.late(seal: false, hotswap: true);
        expect(coupler.trunk.runtimeType.toString(), contains('_DetachableHotswapTrunkProxy'));

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        coupler.couple(t1);
        final lines1 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines1, ['trunk_1_a']);

        coupler.couple(t2);
        final lines2 = coupler.trunk.lines.map((c) => c.data).toList();
        expect(lines2, ['trunk_2_a']);
        expect(disposeCount1, 0);

        await Future.microtask(() {});
        expect(disposeCount1, 1);

        terminal.deactivate();
        expect(disposeCount2, 1);
      });
    });
  });
}
