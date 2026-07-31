// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('Coral Extensions Comprehensive Tests', () {
    group('CoralExtension Tests', () {
      test('toBroadcaster() creates functional CoralBroadcaster', () {
        final coral = Coral.data('test_data');
        final broadcaster = coral.toBroadcaster();

        expect(broadcaster, isA<CoralBroadcaster<String>>());
        final terminal = broadcaster.coral.toTerminal(() {});
        terminal.activate();

        expect(broadcaster.isActivated, isTrue);
        expect(terminal.snapshot.data, 'test_data');
        terminal.deactivate();
      });

      test('toTerminal() attaches directly to source', () {
        int dirtyCount = 0;
        final controller = CoralController<int>(10);
        final terminal = controller.coral.toTerminal(() {
          dirtyCount++;
        });

        terminal.activate();
        expect(terminal.snapshot.data, 10);

        controller.set(20);
        expect(dirtyCount, 1);
        expect(terminal.snapshot.data, 20);

        terminal.deactivate();
      });

      test('observeLifecycle() triggers callbacks on activation, pause, resume, deactivation', () {
        int activatedCount = 0;
        int pausedCount = 0;
        int resumedCount = 0;
        int deactivatedCount = 0;

        final controller = CoralController<int>(1);
        final observedCoral = controller.coral.observeLifecycle(
          onActivated: () => activatedCount++,
          onPaused: () => pausedCount++,
          onResumed: () => resumedCount++,
          onDeactivated: () => deactivatedCount++,
        );

        final terminal = observedCoral.toTerminal(() {});
        expect(activatedCount, 0);

        terminal.activate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 0);

        terminal.deactivate();
        expect(deactivatedCount, 1);
      });
    });

    group('CoralProviderExtension Tests', () {
      test('toBroadcaster() delegates from CoralProvider', () {
        final provider = CoralProvider.coral(Coral.data('val_1'));
        final broadcaster = provider.toBroadcaster();
        expect(broadcaster, isA<CoralBroadcaster<String>>());

        final terminal = broadcaster.coral.toTerminal(() {});
        terminal.activate();
        expect(terminal.snapshot.data, 'val_1');
        terminal.deactivate();
      });

      test('toTerminal() delegates from CoralProvider', () {
        int dirtyFired = 0;
        final provider = CoralProvider.coral(Coral.data('val_2'));
        final terminal = provider.toTerminal(() => dirtyFired++);
        terminal.activate();

        expect(terminal.snapshot.data, 'val_2');
        terminal.deactivate();
      });
    });

    group('CoralProviderComputationExtension Tests', () {
      test('Delegates map, distinct, fallback, fallbackEmptyToNull, guard, cascade, diverge', () {
        // map
        final p1 = CoralProvider.coral(Coral.data(5));
        final mapped = p1.map((val) => val * 2);
        final t1 = mapped.toTerminal(() {});
        t1.activate();
        expect(mapped.data, 10);
        t1.deactivate();

        // distinct
        final p2 = CoralProvider.coral(Coral.data(5));
        final distinctCoral = p2.distinct();
        final t2 = distinctCoral.toTerminal(() {});
        t2.activate();
        expect(distinctCoral.data, 5);
        t2.deactivate();

        // fallback
        final p3 = CoralProvider.coral(Coral<int>.empty());
        final fallbackCoral = p3.fallback(onEmpty: () => 999);
        final t3 = fallbackCoral.toTerminal(() {});
        t3.activate();
        expect(fallbackCoral.data, 999);
        t3.deactivate();

        // fallbackEmptyToNull
        final p4 = CoralProvider.coral(Coral<int>.empty());
        final fallbackNullCoral = p4.fallbackEmptyToNull();
        final t4 = fallbackNullCoral.toTerminal(() {});
        t4.activate();
        expect(fallbackNullCoral.data, isNull);
        t4.deactivate();

        // guard
        final p5 = CoralProvider.coral(Coral.data(5));
        final guarded = p5.guard(
          canProceed: () => true,
          getReasonIfCannotProceed: () => 'Error',
        );
        final t5 = guarded.toTerminal(() {});
        t5.activate();
        expect(guarded.data, 5);
        t5.deactivate();

        // cascade
        final p6 = CoralProvider.coral(Coral.data(5));
        final cascaded = p6.cascade((val) => Coral.data('cascaded_$val'));
        final t6 = cascaded.toTerminal(() {});
        t6.activate();
        expect(cascaded.data, 'cascaded_5');
        t6.deactivate();

        // diverge
        final p7 = CoralProvider.coral(Coral.data(5));
        final diverged = p7.diverge((val) => [Coral.data(val), Coral.data(val + 1)]);
        final t7 = diverged.toTerminal(() {});
        t7.activate();
        expect(diverged.lines.map((c) => c.data).toList(), [5, 6]);
        t7.deactivate();
      });
    });

    group('CoralCollectionExtension Tests', () {
      test('Iterable<Coral<T>>.data extracts data from valid Corals', () {
        final list = <Coral<int>>[
          Coral.data(10),
          Coral.data(20),
          Coral.data(30),
        ];

        final terminals = list.map((c) => c.toTerminal(() {})).toList();
        for (final t in terminals) {
          t.activate();
        }

        expect(list.data.toList(), [10, 20, 30]);

        for (final t in terminals) {
          t.deactivate();
        }
      });

      test('Iterable<Coral<T>>.toTrunk() creates a Trunk bundle', () {
        final list = <Coral<String>>[
          Coral.data('a'),
          Coral.data('b'),
        ];

        final trunk = list.toTrunk();
        expect(trunk, isA<Trunk<String>>());

        final terminal = trunk.toTerminal(() {});
        terminal.activate();

        expect(trunk.lines.map((c) => c.data).toList(), ['a', 'b']);
        terminal.deactivate();
      });
    });

    group('CoralSnapshotCollectionExtension Tests', () {
      test('Iterable<CoralSnapshot<T>>.data extracts data from valid snapshots', () {
        final snapshots = <CoralSnapshot<String>>[
          CoralSnapshot<String>('first'),
          CoralSnapshot<String>('second'),
          CoralSnapshot<String>('third'),
        ];

        expect(snapshots.data.toList(), ['first', 'second', 'third']);
      });

      test('Iterable<CoralSnapshot<T>>.data throws on empty or damaged snapshot', () {
        final emptySnapshots = <CoralSnapshot<String>>[
          CoralSnapshot<String>('valid'),
          CoralSnapshot<String>.empty(),
        ];

        expect(() => emptySnapshots.data.toList(), throwsA(isA<CoralSnapshotExtractionException>()));
      });
    });
  });
}
