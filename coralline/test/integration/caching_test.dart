import 'package:coralline/coralline.dart';
import 'package:test/test.dart';

void main() {
  group('Caching Logic Tests', () {
    test('map should cache computation and PRESERVE cache on deactivation', () {
      final controller = CoralController(1);
      int mapCallCount = 0;
      final mapped = controller.coral.map((v) {
        mapCallCount++;
        return v * 2;
      });

      final term = mapped.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, 2);
      expect(mapCallCount, 1);

      expect(term.snapshot.data, 2);
      expect(mapCallCount, 1); // Cached, no new computation

      term.deactivate();

      // Reading after deactivation should NOT re-compute because cache is preserved!
      expect(mapped.snapshot.data, 2);
      expect(mapCallCount, 1);

      // But if upstream changes while offline, cache is NOT cleared yet
      controller.set(10);
      expect(mapped.snapshot.data, 2); // Still stale because offline!

      // Reactivate to process the pending dirty signal
      term.activate();
      expect(mapped.snapshot.data, 20);
      expect(mapCallCount, 2);
    });

    test('CoralController (EntryCoral) preserves snapshot on deactivation', () {
      final controller = CoralController(10);
      final term = controller.coral.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, 10);

      term.deactivate(); // Deactivates the controller

      // Snapshot is preserved
      expect(controller.coral.isEmpty, false);
      expect(controller.coral.data, 10);
    });

    test('CoralComputation caches and PRESERVES on deactivation', () {
      final controller = CoralController(5);
      int computeCount = 0;

      final computation = _TestComputation(controller.coral, () => computeCount++);
      final term = computation.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, 5);
      expect(computeCount, 1);

      expect(term.snapshot.data, 5);
      expect(computeCount, 1); // cached

      term.deactivate();

      // Should NOT re-compute after deactivation because the cache is preserved
      expect(computation.coral.snapshot.data, 5);
      expect(computeCount, 1);

      // If upstream changes, the dirty signal is buffered because the node is deactivated
      controller.set(10);

      // While deactivated, it returns the stale cache
      expect(computation.coral.snapshot.data, 5);
      expect(computeCount, 1);

      // Upon reactivation, the buffered dirty signal clears the cache, forcing re-computation
      term.activate();
      expect(computation.coral.snapshot.data, 10);
      expect(computeCount, 2);
    });
  });
}

base class _TestComputation extends ComplexComputation<int> {
  _TestComputation(this.source, this.onCompute);

  final Coral<int> source;
  final void Function() onCompute;

  @override
  Iterable<CoralNode> manifest() => [source];

  @override
  int compute() {
    onCompute();
    return source.data;
  }
}
