import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('keyedDiverge', () {
    test('reuses cached nodes for the same keys and garbages collects stale ones', () {
      int creationCount = 0;

      final source = CoralController<Iterable<String>>(["a", "b"]);

      final trunk = source.coral.keyed.diverge(
        key: (item) => item,
        builder: (item) {
          creationCount++;
          return Coral.data(item.toUpperCase());
        },
      );

      final terminal = trunk.toTerminal(() {});
      terminal.activate();

      // Initially 2 elements
      final snapshot1 = terminal.snapshot;
      expect(snapshot1.lines.length, 2);
      expect(creationCount, 2);

      // Get the exact instances of the first two lines
      final lineA = snapshot1.lines.elementAt(0);
      final lineB = snapshot1.lines.elementAt(1);

      // Emit same data, plus a new one
      source.set(["a", "b", "c"]);

      final snapshot2 = terminal.snapshot;
      expect(snapshot2.lines.length, 3);
      expect(creationCount, 3, reason: 'Only 1 new node should be created');

      // The first two lines should be EXACTLY the same instances
      expect(identical(snapshot2.lines.elementAt(0), lineA), isTrue);
      expect(identical(snapshot2.lines.elementAt(1), lineB), isTrue);

      // Emit missing some data (remove 'b')
      source.set(["a", "c", "d"]);

      final snapshot3 = terminal.snapshot;
      expect(snapshot3.lines.length, 3);
      expect(creationCount, 4, reason: 'Only d was created');

      // 'a' should still be the same
      expect(identical(snapshot3.lines.elementAt(0), lineA), isTrue);
      // 'c' is the same instance as before
      expect(identical(snapshot3.lines.elementAt(1), snapshot2.lines.elementAt(2)), isTrue);

      // Add 'b' back, it should be a NEW instance because the old 'b' was garbage collected.
      source.set(["a", "b"]);
      final snapshot4 = terminal.snapshot;
      expect(snapshot4.lines.length, 2);
      expect(creationCount, 5, reason: 'b should be created anew because old b was GCed');

      expect(identical(snapshot4.lines.elementAt(0), lineA), isTrue);
      expect(identical(snapshot4.lines.elementAt(1), lineB), isFalse, reason: 'Old b instance should not be reused');

      terminal.deactivate();
    });
  });
}
