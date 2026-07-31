import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

class MockObject {
  final String id;
  MockObject(this.id);
}

void main() {
  group('keyedMap', () {
    test('reuses cached objects and clears stale ones', () {
      int creationCount = 0;

      final source = CoralController<Iterable<String>>(["a", "b"]);

      final mapped = source.coral.keyed.map(
        key: (item) => item,
        convert: (item) {
          creationCount++;
          return MockObject(item);
        },
      );

      final terminal = mapped.toTerminal(() {});
      terminal.activate();

      final snapshot1 = terminal.snapshot;
      expect(snapshot1.data.length, 2);
      expect(creationCount, 2);

      final objA = snapshot1.data.elementAt(0);

      // Change data (remove 'b', add 'c')
      source.set(["a", "c"]);

      final snapshot2 = terminal.snapshot;
      expect(snapshot2.data.length, 2);
      expect(creationCount, 3); // 'c' created
      expect(identical(snapshot2.data.elementAt(0), objA), isTrue); // 'a' reused

      // Empty data
      source.set([]);
      final snapshot3 = terminal.snapshot; // Trigger computation
      expect(snapshot3.data.isEmpty, isTrue); // Check data, not state

      terminal.deactivate();
    });

    test('error isolation: builder failure clears cache and returns damaged', () {
      final source = CoralController<Iterable<String>>(["a", "b", "c"]);

      final mapped = source.coral.keyed.map(
        key: (item) => item,
        convert: (item) {
          if (item == 'c') throw Exception("Builder Failed on c");
          return MockObject(item);
        },
      );

      final terminal = mapped.toTerminal(() {});
      terminal.activate();

      final snapshot = terminal.snapshot;
      expect(snapshot.isDamaged, isTrue);
      expect(snapshot.error.toString(), contains("Builder Failed on c"));

      terminal.deactivate();
    });
  });
}
