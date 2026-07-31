// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('3. Lifecycle Synchronization (Lifecycle Authority)', () {
    test('Activate / Deactivate Propagation', () {
      int fetchCount = 0;
      int disposeCount = 0;

      final resourceCoral = Coral<int>.resource(
        create: () {
          fetchCount++;
          return 42;
        },
        dispose: (val) {
          disposeCount++;
        },
      );

      final terminal = resourceCoral.toTerminal(() {});

      expect(fetchCount, 0, reason: 'Should not fetch before activation');

      terminal.activate();
      expect(fetchCount, 1, reason: 'Fetch should trigger on activation');
      expect(disposeCount, 0, reason: 'Should not dispose while active');

      terminal.deactivate();
      expect(disposeCount, 1, reason: 'Dispose should trigger on deactivation');
    });

    test('Optimistic Handshake: Late pipeline syncs instantly', () {
      final source = CoralController<int>.late();
      final terminal = source.coral.toTerminal(() {});

      terminal.activate(); // Terminal is now Running

      // Inject data later
      source.set(100);
      expect(terminal.snapshot.dataOrNull, 100);

      terminal.deactivate();
    });

    test('Broadcaster Lifecycle Reference Counting', () async {
      int fetchCount = 0;
      int disposeCount = 0;

      final resourceCoral = Coral<int>.resource(
        create: () {
          fetchCount++;
          return 1;
        },
        dispose: (v) {
          disposeCount++;
        },
      );

      // Create a 1:N broadcaster controller around the resource
      // Note: We simulate this by chaining it through a broadcaster manually
      final broadcaster = CoralBroadcaster(resourceCoral);

      final t1 = broadcaster.coral.toTerminal(() {});
      final t2 = broadcaster.coral.toTerminal(() {});

      t1.activate();
      expect(fetchCount, 1, reason: 'First terminal activates the resource');

      t2.activate();
      expect(fetchCount, 1, reason: 'Second terminal DOES NOT trigger another fetch');

      t1.deactivate();
      expect(disposeCount, 0, reason: 'First terminal deactivating DOES NOT dispose resource because t2 is alive');

      t2.deactivate();
      expect(disposeCount, 0, reason: 'Disposal is deferred to the microtask queue');

      await Future.microtask(() {});
      expect(disposeCount, 1, reason: 'Resource must be disposed after all terminals deactivate');
    });
  });
}
