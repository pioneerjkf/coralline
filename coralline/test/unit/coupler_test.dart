// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('CoralCoupler & TrunkCoupler Comprehensive Unit Tests', () {
    group('CoralCoupler API Tests', () {
      test('CoralCoupler status getters (isActivated, isRunning, isPaused, isDeactivated)', () {
        final c1 = Coral.data('initial');
        final coupler = CoralCoupler<String>(c1);

        expect(coupler.isActivated, isFalse);
        expect(coupler.isRunning, isFalse);
        expect(coupler.isDeactivated, isTrue, reason: 'Dormant before activation');

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        expect(coupler.isActivated, isTrue);
        expect(coupler.isRunning, isTrue);
        expect(coupler.isDeactivated, isFalse);

        terminal.deactivate();
        expect(coupler.isActivated, isFalse);
        expect(coupler.isDeactivated, isTrue);
      });

      test('coupleGuarded() handles normal return and catches exceptions into damaged state', () {
        final coupler = CoralCoupler<String>.late();
        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        // 1. Normal return callback
        coupler.coupleGuarded(() => Coral.data('guarded_success'));
        expect(coupler.snapshot.data, 'guarded_success');

        // 2. Exception throwing callback -> Catches exception & sets damaged state
        coupler.coupleGuarded(() {
          throw FormatException('Guarded Failure');
        });

        expect(coupler.snapshot.isDamaged, isTrue);
        expect(coupler.snapshot.error, isA<FormatException>());
        expect((coupler.snapshot.error as FormatException).message, 'Guarded Failure');

        terminal.deactivate();
      });

      test('decouple() clears active inbound node into empty state', () {
        final coupler = CoralCoupler<String>(Coral.data('hello'));
        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        expect(coupler.snapshot.data, 'hello');

        coupler.decouple();
        expect(coupler.snapshot.isEmpty, isTrue);

        terminal.deactivate();
      });

      test('tryDecoupling() decouples only when matching coralNode reference', () {
        final c1 = Coral.data('node_1');
        final c2 = Coral.data('node_2');
        final coupler = CoralCoupler<String>(c1);

        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        // Try decoupling with unmatched node -> returns false, keeps c1
        final resultWrong = coupler.tryDecoupling(c2);
        expect(resultWrong, isFalse);
        expect(coupler.snapshot.data, 'node_1');

        // Try decoupling with exact matching c1 -> returns true, decouples c1
        final resultRight = coupler.tryDecoupling(c1);
        expect(resultRight, isTrue);
        expect(coupler.snapshot.isEmpty, isTrue);

        terminal.deactivate();
      });

      test('setError() injects manual error into coupler', () {
        final coupler = CoralCoupler<int>(Coral.data(100));
        final terminal = coupler.coral.toTerminal(() {});
        terminal.activate();

        expect(coupler.snapshot.data, 100);

        final customError = StateError('Manual Error Injection');
        coupler.setError(customError);

        expect(coupler.snapshot.isDamaged, isTrue);
        expect(coupler.snapshot.error, customError);

        terminal.deactivate();
      });
    });

    group('TrunkCoupler API Tests', () {
      test('TrunkCoupler status getters (isActivated, isRunning, isPaused, isDeactivated)', () {
        final trunk = [Coral.data('t1')].toTrunk();
        final coupler = TrunkCoupler<String>(trunk);

        expect(coupler.isActivated, isFalse);
        expect(coupler.isRunning, isFalse);
        expect(coupler.isDeactivated, isTrue, reason: 'Dormant before activation');

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        expect(coupler.isActivated, isTrue);
        expect(coupler.isRunning, isTrue);
        expect(coupler.isDeactivated, isFalse);

        terminal.deactivate();
        expect(coupler.isActivated, isFalse);
        expect(coupler.isDeactivated, isTrue);
      });

      test('coupleGuarded() handles normal return and catches exceptions into damaged state', () {
        final coupler = TrunkCoupler<String>.late();
        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        // 1. Normal return callback
        coupler.coupleGuarded(() => [Coral.data('guarded_trunk')].toTrunk());
        expect(coupler.snapshot.lines.first.snapshot.data, 'guarded_trunk');

        // 2. Exception throwing callback -> Catches exception & sets damaged state
        coupler.coupleGuarded(() {
          throw ArgumentError('Trunk Guarded Error');
        });

        expect(coupler.snapshot.isDamaged, isTrue);
        expect(coupler.snapshot.error, isA<ArgumentError>());

        terminal.deactivate();
      });

      test('decouple() clears active inbound trunk into empty state', () {
        final coupler = TrunkCoupler<String>([Coral.data('trunk_data')].toTrunk());
        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        expect(coupler.snapshot.lines.first.snapshot.data, 'trunk_data');

        coupler.decouple();
        expect(coupler.snapshot.lines.isEmpty, isTrue);

        terminal.deactivate();
      });

      test('tryDecoupling() decouples only when matching trunk reference', () {
        final t1 = [Coral.data('t1')].toTrunk();
        final t2 = [Coral.data('t2')].toTrunk();
        final coupler = TrunkCoupler<String>(t1);

        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        // Unmatched trunk -> false
        final resultWrong = coupler.tryDecoupling(t2);
        expect(resultWrong, isFalse);
        expect(coupler.snapshot.lines.isEmpty, isFalse);

        // Matching trunk t1 -> true
        final resultRight = coupler.tryDecoupling(t1);
        expect(resultRight, isTrue);
        expect(coupler.snapshot.lines.isEmpty, isTrue);

        terminal.deactivate();
      });

      test('setError() injects manual error into trunk coupler', () {
        final coupler = TrunkCoupler<int>([Coral.data(500)].toTrunk());
        final terminal = coupler.trunk.toTerminal(() {});
        terminal.activate();

        expect(coupler.snapshot.lines.first.snapshot.data, 500);

        final error = RangeError('Trunk Out Of Bounds');
        coupler.setError(error);

        expect(coupler.snapshot.isDamaged, isTrue);
        expect(coupler.snapshot.error, error);

        terminal.deactivate();
      });
    });

    group('CoralCoupler All Factory Combinations', () {
      test('CoralCoupler default & late factories with all seal & hotswap permutations', () {
        final c1 = Coral.data('v1');

        final cc1 = CoralCoupler(c1, seal: true, hotswap: true);
        final cc2 = CoralCoupler(Coral.data('v2'), seal: true, hotswap: false);
        final cc3 = CoralCoupler(Coral.data('v3'), seal: false, hotswap: true);
        final cc4 = CoralCoupler(Coral.data('v4'), seal: false, hotswap: false);

        final ccLate1 = CoralCoupler<String>.late(seal: true, hotswap: true);
        final ccLate2 = CoralCoupler<String>.late(seal: true, hotswap: false);
        final ccLate3 = CoralCoupler<String>.late(seal: false, hotswap: true);
        final ccLate4 = CoralCoupler<String>.late(seal: false, hotswap: false);

        expect(cc1.coral, isA<Coral<String>>());
        expect(cc2.coral, isA<Coral<String>>());
        expect(cc3.coral, isA<Coral<String>>());
        expect(cc4.coral, isA<Coral<String>>());

        expect(ccLate1.coral, isA<Coral<String>>());
        expect(ccLate2.coral, isA<Coral<String>>());
        expect(ccLate3.coral, isA<Coral<String>>());
        expect(ccLate4.coral, isA<Coral<String>>());

        ccLate1.couple(Coral.data('late1'));
        ccLate2.couple(Coral.data('late2'));
        ccLate3.couple(Coral.data('late3'));
        ccLate4.couple(Coral.data('late4'));

        final t1 = cc1.coral.toTerminal(() {});
        final tLate1 = ccLate1.coral.toTerminal(() {});
        t1.activate();
        tLate1.activate();

        expect(cc1.snapshot.data, 'v1');
        expect(ccLate1.snapshot.data, 'late1');

        t1.deactivate();
        tLate1.deactivate();
      });
    });

    group('TrunkCoupler All Factory Combinations', () {
      test('TrunkCoupler default & late factories with all seal & hotswap permutations', () {
        final t1 = [Coral.data(1)].toTrunk();

        final tc1 = TrunkCoupler(t1, seal: true, hotswap: true);
        final tc2 = TrunkCoupler([Coral.data(2)].toTrunk(), seal: true, hotswap: false);
        final tc3 = TrunkCoupler([Coral.data(3)].toTrunk(), seal: false, hotswap: true);
        final tc4 = TrunkCoupler([Coral.data(4)].toTrunk(), seal: false, hotswap: false);

        final tcLate1 = TrunkCoupler<int>.late(seal: true, hotswap: true);
        final tcLate2 = TrunkCoupler<int>.late(seal: true, hotswap: false);
        final tcLate3 = TrunkCoupler<int>.late(seal: false, hotswap: true);
        final tcLate4 = TrunkCoupler<int>.late(seal: false, hotswap: false);

        expect(tc1.trunk, isA<Trunk<int>>());
        expect(tc2.trunk, isA<Trunk<int>>());
        expect(tc3.trunk, isA<Trunk<int>>());
        expect(tc4.trunk, isA<Trunk<int>>());

        expect(tcLate1.trunk, isA<Trunk<int>>());
        expect(tcLate2.trunk, isA<Trunk<int>>());
        expect(tcLate3.trunk, isA<Trunk<int>>());
        expect(tcLate4.trunk, isA<Trunk<int>>());

        tcLate1.couple([Coral.data(10)].toTrunk());
        tcLate2.couple([Coral.data(20)].toTrunk());
        tcLate3.couple([Coral.data(30)].toTrunk());
        tcLate4.couple([Coral.data(40)].toTrunk());

        final term1 = tc1.trunk.toTerminal(() {});
        final termLate1 = tcLate1.trunk.toTerminal(() {});
        term1.activate();
        termLate1.activate();

        expect(tc1.snapshot.lines.first.data, 1);
        expect(tcLate1.snapshot.lines.first.data, 10);

        term1.deactivate();
        termLate1.deactivate();
      });
    });

    group('Sealed Ownership Stealing Prevention Tests', () {
      test('Coupling a node strongly owned by another sealed parent transition coupler to damaged state', () {
        final sealedCoral = Coral.data('sealed_value');
        final terminal = sealedCoral.toTerminal(() {});

        // Trying to steal sealed node safely transitions coupler into damaged state
        final coupler = CoralCoupler<String>.late();
        final couplerTerminal = coupler.coral.toTerminal(() {});
        couplerTerminal.activate();

        coupler.couple(sealedCoral);

        expect(coupler.snapshot.isDamaged, isTrue);

        couplerTerminal.deactivate();
        terminal.deactivate();
      });
    });
  });
}
