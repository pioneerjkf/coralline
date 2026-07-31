// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('CoralBroadcaster Deactivation Timing & Feature Tests', () {
    group('Immediate Deactivation (_ImmediateDeactivationCoralBroadcaster)', () {
      test('lazyDeactivation: false deactivates upstream synchronously on last detach', () {
        int resourceCreateCount = 0;
        int resourceDisposeCount = 0;

        final upstream = Coral.resource(
          create: () {
            resourceCreateCount++;
            return 'upstream_resource';
          },
          dispose: (_) => resourceDisposeCount++,
        );

        final broadcaster = CoralBroadcaster(upstream, lazyDeactivation: false);
        expect(broadcaster.runtimeType.toString(), contains('_ImmediateDeactivationCoralBroadcaster'));
        expect(broadcaster.isActivated, isFalse);

        final branch1 = broadcaster.coral;
        final terminal1 = branch1.toTerminal(() {});

        // Attach first subscriber
        terminal1.activate();
        expect(broadcaster.isActivated, isTrue);
        expect(resourceCreateCount, 1);
        expect(resourceDisposeCount, 0);

        final branch2 = broadcaster.coral;
        final terminal2 = branch2.toTerminal(() {});
        terminal2.activate();
        expect(resourceCreateCount, 1, reason: 'Shared upstream pipeline');

        // Detach branch1 (1 subscriber remaining)
        terminal1.deactivate();
        expect(broadcaster.isActivated, isTrue);
        expect(resourceDisposeCount, 0);

        // Detach branch2 (0 subscribers remaining) -> Immediate synchronous deactivation!
        terminal2.deactivate();
        expect(broadcaster.isActivated, isFalse, reason: 'Synchronously deactivated on last detach');
        expect(resourceDisposeCount, 1, reason: 'Upstream resource disposed synchronously');
      });
    });

    group('Lazy Deactivation (_LazyDeactivationCoralBroadcaster)', () {
      test('lazyDeactivation: true defers deactivation to microtask queue', () async {
        int resourceCreateCount = 0;
        int resourceDisposeCount = 0;

        final upstream = Coral.resource(
          create: () {
            resourceCreateCount++;
            return 'upstream_resource';
          },
          dispose: (_) => resourceDisposeCount++,
        );

        final broadcaster = CoralBroadcaster(upstream, lazyDeactivation: true);
        expect(broadcaster.runtimeType.toString(), contains('_LazyDeactivationCoralBroadcaster'));
        expect(broadcaster.isActivated, isFalse);

        final branch1 = broadcaster.coral;
        final terminal1 = branch1.toTerminal(() {});

        terminal1.activate();
        expect(broadcaster.isActivated, isTrue);
        expect(resourceCreateCount, 1);
        expect(resourceDisposeCount, 0);

        // Detach last subscriber -> Deactivation is deferred
        terminal1.deactivate();
        expect(broadcaster.isActivated, isTrue, reason: 'Deactivation deferred to microtask');
        expect(resourceDisposeCount, 0, reason: 'Resource not yet disposed synchronously');

        // Wait for microtask queue to flush
        await Future.microtask(() {});
        expect(broadcaster.isActivated, isFalse, reason: 'Deactivated after microtask queue flushes');
        expect(resourceDisposeCount, 1, reason: 'Upstream resource disposed after microtask');
      });

      test('Re-attaching before microtask cancels deferred deactivation', () async {
        int resourceCreateCount = 0;
        int resourceDisposeCount = 0;

        final upstream = Coral.resource(
          create: () {
            resourceCreateCount++;
            return 'upstream_resource';
          },
          dispose: (_) => resourceDisposeCount++,
        );

        final broadcaster = CoralBroadcaster(upstream, lazyDeactivation: true);

        final branch1 = broadcaster.coral;
        final terminal1 = branch1.toTerminal(() {});
        terminal1.activate();
        expect(resourceCreateCount, 1);

        // Detach last subscriber
        terminal1.deactivate();
        expect(broadcaster.isActivated, isTrue);

        // Re-attach a new subscriber before microtask flushes (e.g. Widget rebuild scenario)
        final branch2 = broadcaster.coral;
        final terminal2 = branch2.toTerminal(() {});
        terminal2.activate();

        // Flush microtask queue
        await Future.microtask(() {});

        // Deactivation should have been cancelled, so no rebuild/teardown occurred
        expect(broadcaster.isActivated, isTrue);
        expect(resourceCreateCount, 1, reason: 'Upstream was NOT recreated');
        expect(resourceDisposeCount, 0, reason: 'Upstream was NOT disposed');

        terminal2.deactivate();
        await Future.microtask(() {});
        expect(broadcaster.isActivated, isFalse);
        expect(resourceDisposeCount, 1);
      });
    });

    group('Concurrent Mutation & Safety Guards', () {
      test('Dirty notification broadcasting handles subscriber mutation safely', () {
        final controller = CoralController<int>(0, broadcast: true);
        final broadcaster = CoralBroadcaster(controller.coral);

        int count = 0;
        late CoralTerminal<int> terminal1;
        late CoralTerminal<int> terminal2;

        terminal1 = broadcaster.coral.toTerminal(() {
          count++;
          // Attach terminal2 inside dirty callback
          terminal2.activate();
        });

        terminal2 = broadcaster.coral.toTerminal(() {
          count++;
        });

        terminal1.activate();

        expect(() => controller.set(1), returnsNormally);
        expect(count, greaterThan(0));

        terminal1.deactivate();
        terminal2.deactivate();
      });
    });
  });
}
