import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/collection/list_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('ListCoralElementsExtension', () {
    test('binarySearch and lowerBound locate elements reactively', () {
      final controller = CoralController<List<int>>([10, 20, 30, 40], broadcast: true);

      final indexCoral = controller.coral.elements.binarySearch(30);
      final boundCoral = controller.coral.elements.lowerBound(25);

      final termIdx = indexCoral.toTerminal(() {});
      final termBound = boundCoral.toTerminal(() {});

      termIdx.activate();
      termBound.activate();

      expect(termIdx.snapshot.data, 2);
      expect(termBound.snapshot.data, 2); // 25 would be inserted at index 2 (between 20 and 30)

      termIdx.deactivate();
      termBound.deactivate();
    });

    test(
        'sortedRange, sortedBy, sortedByCompare, shuffledRange, reversedRange, swapped return new lists reactively',
        () {
      final controller = CoralController<List<int>>([5, 3, 9, 1, 7], broadcast: true);

      final sortedRangeCoral =
          controller.coral.elements.sortedRange(1, 4, (a, b) => a.compareTo(b));
      final sortedByCoral = controller.coral.elements.sortedBy((x) => x);
      final shuffledRangeCoral = controller.coral.elements.shuffledRange(1, 4);
      final reversedRangeCoral = controller.coral.elements.reversedRange(1, 4);
      final swappedCoral = controller.coral.elements.swapped(0, 4);

      final t1 = sortedRangeCoral.toTerminal(() {});
      final t2 = sortedByCoral.toTerminal(() {});
      final t3 = shuffledRangeCoral.toTerminal(() {});
      final t4 = reversedRangeCoral.toTerminal(() {});
      final t5 = swappedCoral.toTerminal(() {});

      t1.activate();
      t2.activate();
      t3.activate();
      t4.activate();
      t5.activate();

      expect(t1.snapshot.data, [5, 1, 3, 9, 7]);
      expect(t2.snapshot.data, [1, 3, 5, 7, 9]);
      expect(t4.snapshot.data, [5, 1, 9, 3, 7]);
      expect(t5.snapshot.data, [7, 3, 9, 1, 5]);

      t1.deactivate();
      t2.deactivate();
      t3.deactivate();
      t4.deactivate();
      t5.deactivate();
    });

    test('equals, slice, elementAtOrNull, slices reactively compute list properties', () {
      final controller = CoralController<List<int>>([1, 2, 3], broadcast: true);

      final eqCoral = controller.coral.elements.equals([1, 2, 3]);
      final sliceCoral = controller.coral.elements.slice(1, 3);
      final elemCoral = controller.coral.elements.elementAtOrNull(1);
      final slicesCoral = controller.coral.elements.slices(2);

      final tEq = eqCoral.toTerminal(() {});
      final tSlice = sliceCoral.toTerminal(() {});
      final tElem = elemCoral.toTerminal(() {});
      final tSlices = slicesCoral.toTerminal(() {});

      tEq.activate();
      tSlice.activate();
      tElem.activate();
      tSlices.activate();

      expect(tEq.snapshot.data, true);
      expect(tSlice.snapshot.data, [2, 3]);
      expect(tElem.snapshot.data, 2);
      expect(tSlices.snapshot.data, [
        [1, 2],
        [3]
      ]);

      tEq.deactivate();
      tSlice.deactivate();
      tElem.deactivate();
      tSlices.deactivate();
    });
  });
}
