// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

class MockCoralProvider<T> implements CoralProvider<T> {
  @override
  final Coral<T> coral;

  MockCoralProvider(this.coral);

  @override
  bool get isActivated => coral.isActivated;

  @override
  bool get isDeactivated => coral.isDeactivated;

  @override
  bool get isPaused => coral.isPaused;

  @override
  bool get isRunning => coral.isRunning;
}

void main() {
  group('coral.dart Comprehensive Core & Extensions Unit Tests', () {
    group('CoralSnapshot Core & Equality Tests', () {
      test('CoralSnapshot data, empty, damaged, dataOrElse and isEquivalent', () {
        final sValid1 = const CoralSnapshot<int>(100);
        final sValid2 = const CoralSnapshot<int>(100);
        final sValid3 = const CoralSnapshot<int>(200);
        final sEmpty = const CoralSnapshot<int>.empty();
        final sDamaged = CoralSnapshot<int>.damaged('Error');

        expect(sValid1.isValid, isTrue);
        expect(sValid1.data, 100);
        expect(sValid1.dataOrNull, 100);
        expect(sValid1.dataOrElse(() => 999), 100);

        expect(sEmpty.isEmpty, isTrue);
        expect(sEmpty.dataOrNull, isNull);
        expect(sEmpty.dataOrElse(() => 999), 999);
        expect(() => sEmpty.data, throwsA(isA<CoralSnapshotExtractionException>()));

        expect(sDamaged.isDamaged, isTrue);
        expect(sDamaged.error, 'Error');
        expect(sDamaged.dataOrNull, isNull);
        expect(sDamaged.dataOrElse(() => 999), 999);
        expect(() => sDamaged.data, throwsA(isA<CoralSnapshotExtractionException>()));

        expect(sValid1.isEquivalent(sValid2), isTrue);
        expect(sValid1.isEquivalent(sValid3), isFalse);
        expect(sValid1.isEquivalent(sValid3, (a, b) => a % 100 == b % 100), isTrue);
      });
    });

    group('Coral.resource Lifecycle Tests', () {
      test('Coral.resource invokes create on activation and dispose on deactivation', () {
        bool created = false;
        bool disposed = false;

        final resourceCoral = Coral.resource(
          create: () {
            created = true;
            return 'ResourceInstance';
          },
          dispose: (res) {
            disposed = true;
            expect(res, 'ResourceInstance');
          },
        );

        final terminal = resourceCoral.toTerminal(() {});

        expect(created, isFalse);
        expect(disposed, isFalse);

        terminal.activate();

        expect(created, isTrue);
        expect(resourceCoral.data, 'ResourceInstance');
        expect(disposed, isFalse);

        terminal.deactivate();

        expect(disposed, isTrue);
      });

      test('Coral.resource disposes existing snapshot if present before creating new one on activation', () {
        int createCount = 0;
        final disposedResources = <int>[];

        final resourceCoral = Coral.resource(
          create: () => ++createCount,
          dispose: (res) => disposedResources.add(res),
        );

        // Access snapshot prior to activation (sets _snapshot to empty)
        expect(resourceCoral.snapshot.isEmpty, isTrue);

        final terminal = resourceCoral.toTerminal(() {});
        terminal.activate();

        expect(resourceCoral.data, 1);
        expect(disposedResources, isEmpty);

        // Deactivate and re-activate to verify disposal of old snapshot resource
        terminal.deactivate();
        expect(disposedResources, [1]);

        terminal.activate();
        expect(resourceCoral.data, 2);
        expect(disposedResources, [1]);

        terminal.deactivate();
        expect(disposedResources, [1, 2]);
      });
    });

    group('CoralExtension.observeLifecycle Tests', () {
      test('observeLifecycle triggers callbacks on lifecycle state transitions', () {
        bool activated = false;
        bool paused = false;
        bool resumed = false;
        bool deactivated = false;

        final controller = CoralController<int>(1);
        final observed = controller.coral.observeLifecycle(
          onActivated: () => activated = true,
          onPaused: () => paused = true,
          onResumed: () => resumed = true,
          onDeactivated: () => deactivated = true,
        );

        final terminal = observed.toTerminal(() {});

        terminal.activate();
        expect(activated, isTrue);

        terminal.pause();
        expect(paused, isTrue);

        terminal.resume();
        expect(resumed, isTrue);

        terminal.deactivate();
        expect(deactivated, isTrue);
      });
    });

    group(
        'CoralComputationExtension Operators Tests (cascade, distinct, diverge, fallback, fallbackEmptyToNull, guard, map)',
        () {
      test('distinct suppresses duplicate snapshots', () {
        final controller = CoralController<int>(10);
        int dirtyCount = 0;

        final distinctCoral = controller.coral.distinct();
        final terminal = distinctCoral.toTerminal(() => dirtyCount++);
        terminal.activate();

        expect(distinctCoral.data, 10);

        // Same value set -> dirty flag should NOT be fired
        controller.set(10);
        expect(dirtyCount, 0);

        // Different value set -> dirty flag fired
        controller.set(20);
        expect(dirtyCount, 1);
        expect(distinctCoral.data, 20);

        terminal.deactivate();
      });

      test('fallback recovers empty and damaged states', () {
        final cEmpty = Coral<String>.empty();
        final cDamaged = Coral<String>.damaged('Failure');

        final recoveredEmpty = cEmpty.fallback(onEmpty: () => 'RecoveredEmpty');
        final recoveredDamaged = cDamaged.fallback(onDamage: (err, [stack]) => 'RecoveredDamaged: $err');

        final t1 = recoveredEmpty.toTerminal(() {});
        final t2 = recoveredDamaged.toTerminal(() {});
        t1.activate();
        t2.activate();

        expect(recoveredEmpty.data, 'RecoveredEmpty');
        expect(recoveredDamaged.data, 'RecoveredDamaged: Failure');

        t1.deactivate();
        t2.deactivate();
      });

      test('fallbackEmptyToNull converts empty state to valid null', () {
        final cEmpty = Coral<String>.empty();
        final nullCoral = cEmpty.fallbackEmptyToNull();

        final t = nullCoral.toTerminal(() {});
        t.activate();

        expect(nullCoral.isValid, isTrue);
        expect(nullCoral.data, isNull);

        t.deactivate();
      });

      test('guard damages snapshot when canProceed returns false', () {
        final controller = CoralController<int>(5);
        bool allow = true;

        final guarded = controller.coral.guard(
          canProceed: () => allow,
          getReason: () => 'Access Denied',
        );

        final terminal = guarded.toTerminal(() {});
        terminal.activate();

        expect(guarded.isValid, isTrue);
        expect(guarded.data, 5);

        // Block permission
        allow = false;
        controller.set(10);

        expect(guarded.isDamaged, isTrue);
        expect(guarded.error, 'Access Denied');

        terminal.deactivate();
      });

      test('cascade 8 switch combinations (seal x hotswap x eager)', () {
        final source = Coral.data(1);

        final c1 = source.cascade((i) => Coral.data('1'), seal: true, hotswap: true, eager: true);
        final c2 = source.cascade((i) => Coral.data('2'), seal: true, hotswap: true, eager: false);
        final c3 = source.cascade((i) => Coral.data('3'), seal: true, hotswap: false, eager: true);
        final c4 = source.cascade((i) => Coral.data('4'), seal: true, hotswap: false, eager: false);
        final c5 = source.cascade((i) => Coral.data('5'), seal: false, hotswap: true, eager: true);
        final c6 = source.cascade((i) => Coral.data('6'), seal: false, hotswap: true, eager: false);
        final c7 = source.cascade((i) => Coral.data('7'), seal: false, hotswap: false, eager: true);
        final c8 = source.cascade((i) => Coral.data('8'), seal: false, hotswap: false, eager: false);

        expect(c1.runtimeType.toString(), contains('_SealedHotswapEagerCascadingCoral'));
        expect(c2.runtimeType.toString(), contains('_SealedHotswapLazyCascadingCoral'));
        expect(c3.runtimeType.toString(), contains('_SealedColdswapEagerCascadingCoral'));
        expect(c4.runtimeType.toString(), contains('_SealedColdswapLazyCascadingCoral'));
        expect(c5.runtimeType.toString(), contains('_DetachableHotswapEagerCascadingCoral'));
        expect(c6.runtimeType.toString(), contains('_DetachableHotswapLazyCascadingCoral'));
        expect(c7.runtimeType.toString(), contains('_DetachableColdswapEagerCascadingCoral'));
        expect(c8.runtimeType.toString(), contains('_DetachableColdswapLazyCascadingCoral'));

        final term = c1.toTerminal(() {});
        term.activate();
        expect(c1.data, '1');
        term.deactivate();
      });

      test('diverge 8 switch combinations (seal x hotswap x eager)', () {
        final source = Coral.data(1);

        final tr1 = source.diverge((i) => [Coral.data(i)], seal: true, hotswap: true, eager: true);
        final tr2 = source.diverge((i) => [Coral.data(i)], seal: true, hotswap: true, eager: false);
        final tr3 = source.diverge((i) => [Coral.data(i)], seal: true, hotswap: false, eager: true);
        final tr4 = source.diverge((i) => [Coral.data(i)], seal: true, hotswap: false, eager: false);
        final tr5 = source.diverge((i) => [Coral.data(i)], seal: false, hotswap: true, eager: true);
        final tr6 = source.diverge((i) => [Coral.data(i)], seal: false, hotswap: true, eager: false);
        final tr7 = source.diverge((i) => [Coral.data(i)], seal: false, hotswap: false, eager: true);
        final tr8 = source.diverge((i) => [Coral.data(i)], seal: false, hotswap: false, eager: false);

        expect(tr1.runtimeType.toString(), contains('_SealedHotswapEagerDivergingTrunk'));
        expect(tr2.runtimeType.toString(), contains('_SealedHotswapLazyDivergingTrunk'));
        expect(tr3.runtimeType.toString(), contains('_SealedColdswapEagerDivergingTrunk'));
        expect(tr4.runtimeType.toString(), contains('_SealedColdswapLazyDivergingTrunk'));
        expect(tr5.runtimeType.toString(), contains('_DetachableHotswapEagerDivergingTrunk'));
        expect(tr6.runtimeType.toString(), contains('_DetachableHotswapLazyDivergingTrunk'));
        expect(tr7.runtimeType.toString(), contains('_DetachableColdswapEagerDivergingTrunk'));
        expect(tr8.runtimeType.toString(), contains('_DetachableColdswapLazyDivergingTrunk'));

        final term = tr1.toTerminal(() {});
        term.activate();
        expect(tr1.lines.first.data, 1);
        term.deactivate();
      });
    });

    group('CoralProvider & CoralProviderComputationExtension Tests', () {
      test('CoralProvider.coral factory and computation delegation', () {
        final c = Coral.data(123);
        final provider = CoralProvider.coral(c);

        expect(provider.coral, same(c));

        final p1 = CoralProvider.coral(Coral.data(10));
        final mapResult = p1.map((v) => v * 2);

        final p2 = CoralProvider.coral(Coral.data(20));
        final fallbackResult = p2.fallback(onEmpty: () => 0);

        final p3 = CoralProvider.coral(Coral.data(30));
        final guardResult = p3.guard(canProceed: () => true);

        final t1 = mapResult.toTerminal(() {});
        final t2 = fallbackResult.toTerminal(() {});
        final t3 = guardResult.toTerminal(() {});

        t1.activate();
        t2.activate();
        t3.activate();

        expect(mapResult.data, 20);
        expect(fallbackResult.data, 20);
        expect(guardResult.data, 30);

        t1.deactivate();
        t2.deactivate();
        t3.deactivate();
      });

      test('CoralBroadcaster with Coral.data supports multiple subscribers', () {
        final provider = CoralBroadcaster(Coral.data(42));

        final t1 = provider.coral.toTerminal(() {});
        final t2 = provider.coral.toTerminal(() {});

        t1.activate();
        t2.activate();

        expect(t1.snapshot.data, equals(42));
        expect(t2.snapshot.data, equals(42));

        t1.deactivate();
        t2.deactivate();
      });
    });
  });
}
