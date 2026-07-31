// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('snapshot.dart Collection Extensions Comprehensive Tests', () {
    group('CorallineSnapshotCollectionExtension Tests', () {
      test('all valid snapshots collection', () {
        final snapshots = <CoralSnapshot<int>>[
          const CoralSnapshot(1),
          const CoralSnapshot(2),
          const CoralSnapshot(3),
        ];

        expect(snapshots.areAllValid(), isTrue);
        expect(snapshots.hasAnyEmpty(), isFalse);
        expect(snapshots.hasAnyDamaged(), isFalse);
        expect(snapshots.hasAnyInvalid(), isFalse);
        expect(snapshots.whereEmpty(), isEmpty);
        expect(snapshots.whereDamaged(), isEmpty);
        expect(snapshots.whereInvalid(), isEmpty);
      });

      test('mixed snapshots collection (valid, empty, damaged)', () {
        final sValid1 = const CoralSnapshot(10);
        final sEmpty1 = const CoralSnapshot<int>.empty();
        final sDamaged1 = CoralSnapshot<int>.damaged('Snapshot Error');
        final sValid2 = const CoralSnapshot(20);
        final sEmpty2 = const CoralSnapshot<int>.empty();

        final snapshots = <CoralSnapshot<int>>[
          sValid1,
          sEmpty1,
          sDamaged1,
          sValid2,
          sEmpty2,
        ];

        expect(snapshots.areAllValid(), isFalse);
        expect(snapshots.hasAnyEmpty(), isTrue);
        expect(snapshots.hasAnyDamaged(), isTrue);
        expect(snapshots.hasAnyInvalid(), isTrue);

        expect(snapshots.whereEmpty().toList(), [sEmpty1, sEmpty2]);
        expect(snapshots.whereDamaged().toList(), [sDamaged1]);
        expect(snapshots.whereInvalid().toList(), [sEmpty1, sDamaged1, sEmpty2]);
      });
    });

    group('CorallineSnapshotDelegatorCollectionExtension Tests', () {
      test('all valid delegators collection', () {
        final corals = <Coral<int>>[
          Coral.data(100),
          Coral.data(200),
        ];

        final terminals = corals.map((c) => c.toTerminal(() {})).toList();
        for (final t in terminals) {
          t.activate();
        }

        expect(corals.areAllValid(), isTrue);
        expect(corals.hasAnyEmpty(), isFalse);
        expect(corals.hasAnyDamaged(), isFalse);
        expect(corals.hasAnyInvalid(), isFalse);
        expect(corals.whereEmpty(), isEmpty);
        expect(corals.whereDamaged(), isEmpty);
        expect(corals.whereInvalid(), isEmpty);

        for (final t in terminals) {
          t.deactivate();
        }
      });

      test('mixed delegators collection (valid, empty, damaged)', () {
        final cValid = Coral.data(1);
        final cEmpty = Coral<int>.empty();
        final cDamaged = Coral<int>.damaged(Exception('Delegator Damage'));

        final corals = <Coral<int>>[cValid, cEmpty, cDamaged];

        final t1 = cValid.toTerminal(() {});
        final t2 = cEmpty.toTerminal(() {});
        final t3 = cDamaged.toTerminal(() {});
        t1.activate();
        t2.activate();
        t3.activate();

        expect(corals.areAllValid(), isFalse);
        expect(corals.hasAnyEmpty(), isTrue);
        expect(corals.hasAnyDamaged(), isTrue);
        expect(corals.hasAnyInvalid(), isTrue);

        expect(corals.whereEmpty().toList(), [cEmpty]);
        expect(corals.whereDamaged().toList(), [cDamaged]);
        expect(corals.whereInvalid().toList(), [cEmpty, cDamaged]);

        t1.deactivate();
        t2.deactivate();
        t3.deactivate();
      });
    });
  });
}
