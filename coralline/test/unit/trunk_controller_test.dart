// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('TrunkController Comprehensive Unit Tests', () {
    test('Standard TrunkController initialization and set/lines mutation', () {
      final coral1 = CoralController<int>(10).coral;
      final coral2 = CoralController<int>(20).coral;
      final controller = TrunkController<int>([coral1, coral2]);

      expect(controller.isValid, isTrue);
      expect(controller.lines.length, equals(2));
      expect(controller.lines[0].snapshot.data, equals(10));
      expect(controller.lines[1].snapshot.data, equals(20));

      final coral3 = CoralController<int>(30).coral;
      controller.set([coral3]);

      expect(controller.lines.length, equals(1));
      expect(controller.lines[0].snapshot.data, equals(30));
    });

    test('TrunkController.late initialization and delayed set', () {
      final controller = TrunkController<int>.late();

      expect(controller.isEmpty, isTrue);
      expect(controller.isValid, isFalse);
      expect(() => controller.lines, throwsA(isA<CoralSnapshotExtractionException>()));

      final coral1 = CoralController<int>(100).coral;
      controller.set([coral1]);

      expect(controller.isValid, isTrue);
      expect(controller.lines.length, equals(1));
      expect(controller.lines[0].snapshot.data, equals(100));
    });

    test('TrunkController setGuarded, setError, and empty', () {
      final controller = TrunkController<int>.late();

      // Guarded failure
      controller.setGuarded(() => throw Exception('Calculation error'));
      expect(controller.isDamaged, isTrue);
      expect(controller.error, isA<Exception>());

      // Guarded success
      final coral1 = CoralController<int>(50).coral;
      controller.setGuarded(() => [coral1]);
      expect(controller.isValid, isTrue);
      expect(controller.lines.length, equals(1));

      // setError
      controller.setError('Manual Error');
      expect(controller.isDamaged, isTrue);
      expect(controller.error, equals('Manual Error'));

      // release
      controller.release();
      expect(controller.isEmpty, isTrue);
    });

    test('TrunkController downstream pipeline integration via aggregate', () {
      final c1 = CoralController<int>(10);
      final c2 = CoralController<int>(20);
      final trunkController = TrunkController<int>([c1.coral, c2.coral]);

      final sumCoral = trunkController.aggregate(
        (lines) => lines.fold<int>(0, (sum, line) => sum + line.snapshot.data),
      );

      var dirtyCount = 0;
      final terminal = sumCoral.toTerminal(() => dirtyCount++);
      terminal.activate();

      expect(terminal.data, equals(30));

      c1.set(15);
      expect(dirtyCount, equals(1));
      expect(terminal.data, equals(35));

      final c3 = CoralController<int>(100);
      trunkController.set([c1.coral, c2.coral, c3.coral]);
      expect(dirtyCount, equals(2));
      expect(terminal.data, equals(135));
    });

    test('TrunkController seal and hotswap constructor options', () {
      final c1 = CoralController<int>(1).coral;

      final tc1 = TrunkController([c1], seal: true, hotswap: true);
      final tc2 = TrunkController([c1], seal: true, hotswap: false);
      final tc3 = TrunkController([c1], seal: false, hotswap: true);
      final tc4 = TrunkController([c1], seal: false, hotswap: false);

      expect(tc1.trunk.runtimeType.toString(), contains('_SealedHotswapControlledTrunk'));
      expect(tc2.trunk.runtimeType.toString(), contains('_SealedColdswapControlledTrunk'));
      expect(tc3.trunk.runtimeType.toString(), contains('_DetachableHotswapControlledTrunk'));
      expect(tc4.trunk.runtimeType.toString(), contains('_DetachableColdswapControlledTrunk'));

      final tcLate1 = TrunkController<int>.late(seal: true, hotswap: true);
      final tcLate2 = TrunkController<int>.late(seal: true, hotswap: false);
      final tcLate3 = TrunkController<int>.late(seal: false, hotswap: true);
      final tcLate4 = TrunkController<int>.late(seal: false, hotswap: false);

      expect(tcLate1.trunk.runtimeType.toString(), contains('_SealedHotswapControlledTrunk'));
      expect(tcLate2.trunk.runtimeType.toString(), contains('_SealedColdswapControlledTrunk'));
      expect(tcLate3.trunk.runtimeType.toString(), contains('_DetachableHotswapControlledTrunk'));
      expect(tcLate4.trunk.runtimeType.toString(), contains('_DetachableColdswapControlledTrunk'));
    });
  });
}
