import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/collection/iterable_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('GeneralCoralElementsExtension', () {
    test('firstWhereOrNull, lastWhereOrNull, singleWhereOrNull search elements reactively', () {
      final controller =
          CoralController<List<String>>(['apple', 'banana', 'apricot', 'cherry'], broadcast: true);

      final firstA = controller.coral.elements.firstWhereOrNull((e) => e.startsWith('a'));
      final lastA = controller.coral.elements.lastWhereOrNull((e) => e.startsWith('a'));
      final singleC = controller.coral.elements.singleWhereOrNull((e) => e.startsWith('c'));

      final termFirst = firstA.toTerminal(() {});
      final termLast = lastA.toTerminal(() {});
      final termSingle = singleC.toTerminal(() {});

      termFirst.activate();
      termLast.activate();
      termSingle.activate();

      expect(termFirst.snapshot.data, 'apple');
      expect(termLast.snapshot.data, 'apricot');
      expect(termSingle.snapshot.data, 'cherry');

      controller.set(['banana', 'cherry']);
      expect(termFirst.snapshot.data, null);
      expect(termLast.snapshot.data, null);
      expect(termSingle.snapshot.data, 'cherry');

      termFirst.deactivate();
      termLast.deactivate();
      termSingle.deactivate();
    });

    test('whereNotNull filters nulls reactively', () {
      final controller = CoralController<List<int?>>([1, null, 3, null, 5], broadcast: true);

      final nonNulls = controller.coral.elements.whereNotNull;
      final term = nonNulls.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, [1, 3, 5]);

      controller.set([null, null]);
      expect(term.snapshot.data, <int>[]);

      term.deactivate();
    });

    test('mapIndexed and whereIndexed use indices reactively', () {
      final controller = CoralController<List<String>>(['a', 'b', 'c'], broadcast: true);

      final mapped = controller.coral.elements.mapIndexed((idx, val) => '$idx:$val');
      final filtered = controller.coral.elements.whereIndexed((idx, val) => idx.isEven);

      final termMap = mapped.toTerminal(() {});
      final termFilter = filtered.toTerminal(() {});

      termMap.activate();
      termFilter.activate();

      expect(termMap.snapshot.data, ['0:a', '1:b', '2:c']);
      expect(termFilter.snapshot.data, ['a', 'c']);

      termMap.deactivate();
      termFilter.deactivate();
    });

    test('groupBy and slices group collections reactively', () {
      final controller = CoralController<List<int>>([1, 2, 3, 4, 5], broadcast: true);

      final groups = controller.coral.elements.groupBy((x) => x % 2 == 0 ? 'even' : 'odd');
      final sliced = controller.coral.elements.slices(2);

      final termGroups = groups.toTerminal(() {});
      final termSliced = sliced.toTerminal(() {});

      termGroups.activate();
      termSliced.activate();

      expect(termGroups.snapshot.data, {
        'odd': [1, 3, 5],
        'even': [2, 4],
      });
      expect(termSliced.snapshot.data, [
        [1, 2],
        [3, 4],
        [5],
      ]);

      termGroups.deactivate();
      termSliced.deactivate();
    });
  });

  group('New General Extension Tests', () {
    test('whereNot, shuffled, sortedBy, and isSortedBy reactively operate on elements', () {
      final controller = CoralController<List<int>>([1, 2, 3, 4], broadcast: true);

      final whereNotCoral = controller.coral.elements.whereNot((x) => x.isEven);
      final isSortedCoral = controller.coral.elements.isSortedBy((x) => x);

      final tWN = whereNotCoral.toTerminal(() {});
      final tIS = isSortedCoral.toTerminal(() {});

      tWN.activate();
      tIS.activate();

      expect(tWN.snapshot.data, [1, 3]);
      expect(tIS.snapshot.data, true);

      controller.set([3, 1, 4, 2]);
      expect(tWN.snapshot.data, [3, 1]);
      expect(tIS.snapshot.data, false);

      tWN.deactivate();
      tIS.deactivate();
    });

    test('reduceIndexed, foldIndexed, none, and indexed predicates reactively compute elements',
        () {
      final controller = CoralController<List<int>>([1, 2, 3], broadcast: true);

      final redCoral = controller.coral.elements.reduceIndexed((idx, prev, el) => prev + el + idx);
      final foldCoral =
          controller.coral.elements.foldIndexed<int>(10, (idx, prev, el) => prev + el + idx);
      final noneCoral = controller.coral.elements.none((x) => x > 5);
      final noneIndexedCoral = controller.coral.elements.noneIndexed((idx, x) => x + idx > 5);

      final tRed = redCoral.toTerminal(() {});
      final tFold = foldCoral.toTerminal(() {});
      final tNone = noneCoral.toTerminal(() {});
      final tNoneIndexed = noneIndexedCoral.toTerminal(() {});

      tRed.activate();
      tFold.activate();
      tNone.activate();
      tNoneIndexed.activate();

      expect(tRed.snapshot.data, 1 + 2 + 1 + 3 + 2); // 9
      expect(tFold.snapshot.data, 10 + 1 + 0 + 2 + 1 + 3 + 2); // 19
      expect(tNone.snapshot.data, true);
      expect(tNoneIndexed.snapshot.data, true);

      tRed.deactivate();
      tFold.deactivate();
      tNone.deactivate();
      tNoneIndexed.deactivate();
    });

    test('splitBefore, splitAfter, splitBetween reactively partition collections', () {
      final controller = CoralController<List<int>>([1, 0, 2, 1, 5, 7, 6], broadcast: true);

      final splitCoral = controller.coral.elements.splitBefore((x) => x > 3);
      final tSplit = splitCoral.toTerminal(() {});
      tSplit.activate();

      expect(tSplit.snapshot.data, [
        [1, 0, 2, 1],
        [5],
        [7],
        [6]
      ]);

      tSplit.deactivate();
    });

    test('flattenedToList, flattenedToSet reactively flatten nested collections', () {
      final controller = CoralController<List<List<int>>>([
        [1, 2],
        [3],
        [3, 4]
      ], broadcast: true);

      final flatCoral = controller.coral.elements.flattenedToList;
      final flatSetCoral = controller.coral.elements.flattenedToSet;

      final tList = flatCoral.toTerminal(() {});
      final tSet = flatSetCoral.toTerminal(() {});

      tList.activate();
      tSet.activate();

      expect(tList.snapshot.data, [1, 2, 3, 3, 4]);
      expect(tSet.snapshot.data, {1, 2, 3, 4});

      tList.deactivate();
      tSet.deactivate();
    });
  });
}
