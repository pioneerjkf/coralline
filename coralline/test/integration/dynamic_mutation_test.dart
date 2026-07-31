// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('5. Dynamic Graph Mutation (Hot-swapping & Mooring)', () {
    test('Hot-swapping allows dynamic pipeline changes without crashing', () {
      final sourceA = CoralController<int>(10);
      final sourceB = CoralController<int>(20);

      // Use cascading to dynamically switch between sourceA and sourceB
      final switcher = CoralController<bool>(true);

      final cascade = switcher.coral.cascade((useA) {
        return useA ? sourceA.coral : sourceB.coral;
      }, hotswap: true);

      final terminal = cascade.toTerminal(() {});
      terminal.activate();

      expect(terminal.snapshot.dataOrNull, 10);

      // Perform hot-swap
      switcher.set(false);

      // Immediately pull new data (Push-Dirty Pull-Data)
      expect(terminal.snapshot.dataOrNull, 20, reason: 'Pipeline should seamlessly swap to sourceB');

      terminal.deactivate();
    });

    test('Sealed Coupling (hotswap: false) destroys old pipeline on swap', () {
      final switcher = CoralController<bool>(true);

      int fetchA = 0;
      int fetchB = 0;

      final cascade = switcher.coral.cascade((useA) {
        if (useA) {
          return Coral.resource(
              create: () {
                fetchA++;
                return 1;
              },
              dispose: (_) {});
        } else {
          return Coral.resource(
              create: () {
                fetchB++;
                return 2;
              },
              dispose: (_) {});
        }
      }, hotswap: false); // Sealed

      final terminal = cascade.toTerminal(() {});
      terminal.activate();

      expect(terminal.snapshot.dataOrNull, 1); // Pull data to trigger lazy fetch
      expect(fetchA, 1);

      // Trigger swap. Because hotswap is false, it completely rebuilds.
      switcher.set(false);

      expect(terminal.snapshot.dataOrNull, 2);
      expect(fetchB, 1);

      terminal.deactivate();
    });
  });
}
