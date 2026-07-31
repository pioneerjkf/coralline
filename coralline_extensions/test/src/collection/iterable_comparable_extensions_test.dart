import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/collection/iterable_comparable_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('ComparableCoralElementsExtension', () {
    test('maxOrNull and minOrNull compute comparable elements reactively', () {
      final controller = CoralController<List<int>>([5, 3, 9, 1, 7], broadcast: true);

      final maxCoral = controller.coral.elements.maxOrNull;
      final minCoral = controller.coral.elements.minOrNull;

      final termMax = maxCoral.toTerminal(() {});
      final termMin = minCoral.toTerminal(() {});
      termMax.activate();
      termMin.activate();

      expect(termMax.snapshot.data, 9);
      expect(termMin.snapshot.data, 1);

      controller.set([10, 20, 5]);
      expect(termMax.snapshot.data, 20);
      expect(termMin.snapshot.data, 5);

      controller.set([]);
      expect(termMax.snapshot.data, null);
      expect(termMin.snapshot.data, null);

      termMax.deactivate();
      termMin.deactivate();
    });

    test('max and min compute comparable elements reactively and throw when empty', () {
      final controller = CoralController<List<int>>([5, 3, 9, 1, 7], broadcast: true);

      final maxCoral = controller.coral.elements.max;
      final minCoral = controller.coral.elements.min;

      final termMax = maxCoral.toTerminal(() {});
      final termMin = minCoral.toTerminal(() {});
      termMax.activate();
      termMin.activate();

      expect(termMax.snapshot.data, 9);
      expect(termMin.snapshot.data, 1);

      controller.set([10, 20, 5]);
      expect(termMax.snapshot.data, 20);
      expect(termMin.snapshot.data, 5);

      controller.set([]);
      expect(termMax.snapshot.isDamaged, isTrue);
      expect(termMax.snapshot.error, isA<StateError>());
      expect(termMin.snapshot.isDamaged, isTrue);
      expect(termMin.snapshot.error, isA<StateError>());

      termMax.deactivate();
      termMin.deactivate();
    });

    test('isSorted detects sorted state reactively', () {
      final controller = CoralController<List<int>>([1, 2, 3, 4, 5], broadcast: true);
      final isSortedCoral = controller.coral.elements.isSorted();

      final term = isSortedCoral.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, true);

      controller.set([1, 3, 2, 4]);
      expect(term.snapshot.data, false);

      controller.set([5]);
      expect(term.snapshot.data, true);

      controller.set([]);
      expect(term.snapshot.data, true);

      term.deactivate();
    });

    test('sorted and sortedDescending produce sorted lists reactively', () {
      final controller = CoralController<List<int>>([5, 3, 9, 1, 7], broadcast: true);
      final sortedCoral = controller.coral.elements.sorted;
      final sortedDescCoral = controller.coral.elements.sortedDescending;

      final termSorted = sortedCoral.toTerminal(() {});
      final termSortedDesc = sortedDescCoral.toTerminal(() {});
      termSorted.activate();
      termSortedDesc.activate();

      expect(termSorted.snapshot.data, [1, 3, 5, 7, 9]);
      expect(termSortedDesc.snapshot.data, [9, 7, 5, 3, 1]);

      controller.set([10, 20, 5]);
      expect(termSorted.snapshot.data, [5, 10, 20]);
      expect(termSortedDesc.snapshot.data, [20, 10, 5]);

      controller.set([]);
      expect(termSorted.snapshot.data, isEmpty);
      expect(termSortedDesc.snapshot.data, isEmpty);

      termSorted.deactivate();
      termSortedDesc.deactivate();
    });
  });
}
