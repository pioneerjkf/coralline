// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('Trunk Comprehensive Unit Tests', () {
    group('TrunkSnapshot Tests', () {
      test('Valid TrunkSnapshot properties and fail-safe getters', () {
        final c1 = Coral.data(1);
        final c2 = Coral.data(2);
        final snapshot = TrunkSnapshot([c1, c2]);

        expect(snapshot.isValid, isTrue);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.isDamaged, isFalse);
        expect(snapshot.lines, [c1, c2]);
        expect(snapshot.linesOrNull, [c1, c2]);
        expect(snapshot.linesOrEmpty, [c1, c2]);
      });

      test('Empty TrunkSnapshot throws extraction exception on lines', () {
        const snapshot = TrunkSnapshot<int>.empty();

        expect(snapshot.isEmpty, isTrue);
        expect(snapshot.isDamaged, isFalse);
        expect(snapshot.linesOrNull, isNull);
        expect(snapshot.linesOrEmpty, isEmpty);
        expect(() => snapshot.lines, throwsA(isA<CoralSnapshotExtractionException>()));
      });

      test('Damaged TrunkSnapshot exposes error and throws extraction exception on lines', () {
        final err = FormatException('Trunk Damaged Error');
        final stack = StackTrace.current;
        final snapshot = TrunkSnapshot<int>.damaged(err, stack);

        expect(snapshot.isValid, isFalse);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.isDamaged, isTrue);
        expect(snapshot.error, same(err));
        expect(snapshot.stackTrace, same(stack));
        expect(snapshot.linesOrNull, isNull);
        expect(snapshot.linesOrEmpty, isEmpty);
        expect(() => snapshot.lines, throwsA(isA<CoralSnapshotExtractionException>()));
      });
    });

    group('Trunk Factory Constructors Tests', () {
      test('Trunk.of creates valid sealed trunk', () {
        final c1 = Coral.data('x');
        final c2 = Coral.data('y');
        final trunk = Trunk.of([c1, c2]);

        final terminal = trunk.toTerminal(() {});
        terminal.activate();

        expect(trunk.isValid, isTrue);
        expect(trunk.isEmpty, isFalse);
        expect(trunk.isDamaged, isFalse);
        expect(trunk.lines, [c1, c2]);

        terminal.deactivate();
      });

      test('Trunk.of with seal and hotswap options', () {
        final c1 = Coral.data('a');
        final c2 = Coral.data('b');

        final t1 = Trunk.of([c1, c2], seal: true);
        final t2 = Trunk.of([c1, c2], seal: false, hotswap: false);
        final t3 = Trunk.of([c1, c2], seal: false, hotswap: true);

        expect(t1.isValid, isTrue);
        expect(t2.isValid, isTrue);
        expect(t3.isValid, isTrue);

        expect([c1, c2].toTrunk(seal: false, hotswap: true).isValid, isTrue);

        expect(
          () => Trunk.of([c1, c2], seal: true, hotswap: true),
          throwsA(isA<AssertionError>()),
        );
      });

      test('Trunk.empty creates static empty trunk', () {
        final trunk = Trunk<int>.empty();

        expect(trunk.isValid, isTrue);
        expect(trunk.linesOrEmpty, isEmpty);
      });

      test('Trunk.damaged creates static damaged trunk', () {
        final err = StateError('Trunk Failure');
        final trunk = Trunk<int>.damaged(err);

        expect(trunk.isValid, isFalse);
        expect(trunk.isDamaged, isTrue);
        expect(trunk.error, same(err));
      });
    });
  });
}
