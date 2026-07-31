import 'package:test/test.dart';
import 'dart:collection';
import 'package:coralline/coralline.dart';

void main() {
  group('CoralListElements', () {
    test('operator [] look up elements reactively', () {
      final controller = CoralController<List<String>>(['a', 'b', 'c'], broadcast: true);

      final firstElement = controller.coral.elements[0];
      final thirdElement = controller.coral.elements[2];

      final term1 = firstElement.toTerminal(() {});
      final term3 = thirdElement.toTerminal(() {});
      term1.activate();
      term3.activate();

      expect(term1.snapshot.data, 'a');
      expect(term3.snapshot.data, 'c');

      // Change list elements
      controller.set(['x', 'y', 'z']);
      expect(term1.snapshot.data, 'x');
      expect(term3.snapshot.data, 'z');

      term1.deactivate();
      term3.deactivate();
    });

    test('sublist and reversed return unmodifiable views reactively', () {
      final controller = CoralController<List<int>>([1, 2, 3, 4, 5], broadcast: true);

      final sublistCoral = controller.coral.elements.sublist(1, 4);
      final reversedCoral = controller.coral.elements.reversed;

      final termSub = sublistCoral.toTerminal(() {});
      final termRev = reversedCoral.toTerminal(() {});
      termSub.activate();
      termRev.activate();

      expect(termSub.snapshot.data, [2, 3, 4]);
      expect(termRev.snapshot.data, [5, 4, 3, 2, 1]);

      // Check immutability
      expect(() => (termSub.snapshot.data as List).add(6), throwsUnsupportedError);

      controller.set([10, 20, 30, 40, 50, 60]);
      expect(termSub.snapshot.data, [20, 30, 40]);
      expect(termRev.snapshot.data, [60, 50, 40, 30, 20, 10]);

      termSub.deactivate();
      termRev.deactivate();
    });
  });

  group('CoralSetElements', () {
    test('union, intersection, difference compute set operations and preserve Set type', () {
      final controller = CoralController<Set<int>>({1, 2, 3}, broadcast: true);

      final unionCoral = controller.coral.elements.union({3, 4, 5});
      final intersectionCoral = controller.coral.elements.intersection({2, 3, 4});
      final differenceCoral = controller.coral.elements.difference({1});

      final termUnion = unionCoral.toTerminal(() {});
      final termInter = intersectionCoral.toTerminal(() {});
      final termDiff = differenceCoral.toTerminal(() {});

      termUnion.activate();
      termInter.activate();
      termDiff.activate();

      expect(termUnion.snapshot.data, {1, 2, 3, 4, 5});
      expect(termInter.snapshot.data, {2, 3});
      expect(termDiff.snapshot.data, {2, 3});

      // Verify Set type is preserved
      expect(termUnion.snapshot.data, isA<Set<int>>());
      expect(() => (termUnion.snapshot.data as Set).add(6), throwsUnsupportedError);

      controller.set({3, 4});
      expect(termUnion.snapshot.data, {3, 4, 5});
      expect(termInter.snapshot.data, {3, 4});
      expect(termDiff.snapshot.data, {3, 4});

      termUnion.deactivate();
      termInter.deactivate();
      termDiff.deactivate();
    });

    test('map and where yield unmodifiable lists reactively', () {
      final controller = CoralController<Set<int>>({1, 2, 3}, broadcast: true);

      final mapped = controller.coral.elements.map((e) => 'item-$e');
      final filtered = controller.coral.elements.where((e) => e > 1);

      final termMap = mapped.toTerminal(() {});
      final termFilter = filtered.toTerminal(() {});

      termMap.activate();
      termFilter.activate();

      expect(termMap.snapshot.data, ['item-1', 'item-2', 'item-3']);
      expect(termFilter.snapshot.data, [2, 3]);
      expect(termMap.snapshot.data, isA<List<String>>());
      expect(termFilter.snapshot.data, isA<List<int>>());

      termMap.deactivate();
      termFilter.deactivate();
    });
  });

  group('CoralMapElements', () {
    test('operator [] reads map keys reactively', () {
      final controller = CoralController<Map<String, int>>({'a': 1, 'b': 2}, broadcast: true);

      final valA = controller.coral.elements['a'];
      final valC = controller.coral.elements['c'];

      final termA = valA.toTerminal(() {});
      final termC = valC.toTerminal(() {});

      termA.activate();
      termC.activate();

      expect(termA.snapshot.data, 1);
      expect(termC.snapshot.data, null);

      controller.set({'a': 10, 'c': 30});
      expect(termA.snapshot.data, 10);
      expect(termC.snapshot.data, 30);

      termA.deactivate();
      termC.deactivate();
    });

    test('map and where transform and filter entry-wise reactively', () {
      final controller = CoralController<Map<String, int>>({'a': 1, 'b': 2, 'c': 3}, broadcast: true);

      final mapped = controller.coral.elements.map((k, v) => MapEntry(k.toUpperCase(), v * 10));
      final filtered = controller.coral.elements.where((k, v) => v.isOdd);

      final termMap = mapped.toTerminal(() {});
      final termFilter = filtered.toTerminal(() {});

      termMap.activate();
      termFilter.activate();

      expect(termMap.snapshot.data, {'A': 10, 'B': 20, 'C': 30});
      expect(termFilter.snapshot.data, {'a': 1, 'c': 3});
      expect(termMap.snapshot.data, isA<Map<String, int>>());

      termMap.deactivate();
      termFilter.deactivate();
    });

    test('keys and values extract collections reactively', () {
      final controller = CoralController<Map<String, int>>({'a': 1, 'b': 2}, broadcast: true);

      final keysCoral = controller.coral.elements.keys;
      final valuesCoral = controller.coral.elements.values;

      final termKeys = keysCoral.toTerminal(() {});
      final termValues = valuesCoral.toTerminal(() {});

      termKeys.activate();
      termValues.activate();

      expect(termKeys.snapshot.data, ['a', 'b']);
      expect(termValues.snapshot.data, [1, 2]);

      controller.set({'x': 100});
      expect(termKeys.snapshot.data, ['x']);
      expect(termValues.snapshot.data, [100]);

      termKeys.deactivate();
      termValues.deactivate();
    });
  });

  group('Subtype collection support (HashSet, HashMap, Queue)', () {
    test('HashSet is supported via CoralSetElements', () {
      final set = HashSet<int>.from({10, 20});
      final controller = CoralController<HashSet<int>>(set, broadcast: true);

      final elements = controller.coral.elements;
      expect(elements, isA<CoralSetElements<int>>());

      final unionCoral = elements.union({20, 30});
      final term = unionCoral.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, {10, 20, 30});
      term.deactivate();
    });

    test('HashMap is supported via CoralMapElements', () {
      final map = HashMap<String, int>.from({'x': 100});
      final controller = CoralController<HashMap<String, int>>(map, broadcast: true);

      final elements = controller.coral.elements;
      expect(elements, isA<CoralMapElements<String, int>>());

      final valX = elements['x'];
      final term = valX.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, 100);
      term.deactivate();
    });

    test('Queue is supported via CoralElements', () {
      final queue = Queue<int>.from([1, 2, 3]);
      final controller = CoralController<Queue<int>>(queue, broadcast: true);

      final elements = controller.coral.elements;
      expect(elements, isA<CoralIterableElements<int>>());

      final mapped = elements.map((e) => e * 2);
      final term = mapped.toTerminal(() {});
      term.activate();

      expect(term.snapshot.data, [2, 4, 6]);
      term.deactivate();
    });
  });

  group('New query and search APIs', () {
    test('Iterable query APIs (contains, firstWhere, length)', () {
      final controller = CoralController<List<int>>([1, 2, 3], broadcast: true);

      final containsTwo = controller.coral.elements.contains(2);
      final firstGreaterThanOne = controller.coral.elements.firstWhere((x) => x > 1);
      final len = controller.coral.elements.length;

      final termContains = containsTwo.toTerminal(() {});
      final termFirst = firstGreaterThanOne.toTerminal(() {});
      final termLen = len.toTerminal(() {});

      termContains.activate();
      termFirst.activate();
      termLen.activate();

      expect(termContains.snapshot.data, true);
      expect(termFirst.snapshot.data, 2);
      expect(termLen.snapshot.data, 3);

      controller.set([10]);
      expect(termContains.snapshot.data, false);
      expect(termFirst.snapshot.data, 10);
      expect(termLen.snapshot.data, 1);

      termContains.deactivate();
      termFirst.deactivate();
      termLen.deactivate();
    });

    test('List query APIs (indexOf, asMap)', () {
      final controller = CoralController<List<String>>(['a', 'b'], broadcast: true);

      final idxB = controller.coral.elements.indexOf('b');
      final mapped = controller.coral.elements.asMap();

      final termIdx = idxB.toTerminal(() {});
      final termMap = mapped.toTerminal(() {});

      termIdx.activate();
      termMap.activate();

      expect(termIdx.snapshot.data, 1);
      expect(termMap.snapshot.data, {0: 'a', 1: 'b'});

      termIdx.deactivate();
      termMap.deactivate();
    });

    test('Map query APIs (containsKey, containsValue, length)', () {
      final controller = CoralController<Map<String, int>>({'x': 1}, broadcast: true);

      final hasX = controller.coral.elements.containsKey('x');
      final hasY = controller.coral.elements.containsKey('y');
      final len = controller.coral.elements.length;

      final termHasX = hasX.toTerminal(() {});
      final termHasY = hasY.toTerminal(() {});
      final termLen = len.toTerminal(() {});

      termHasX.activate();
      termHasY.activate();
      termLen.activate();

      expect(termHasX.snapshot.data, true);
      expect(termHasY.snapshot.data, false);
      expect(termLen.snapshot.data, 1);

      termHasX.deactivate();
      termHasY.deactivate();
      termLen.deactivate();
    });
  });

  group('CoralIterableElements coverage', () {
    test('whereType, indexed, and expand reactively', () {
      final controller = CoralController<Iterable<Object>>([1, 'a', 2, 'b'], broadcast: true);

      final whereTypeInt = controller.coral.elements.whereType<int>();
      final indexed = controller.coral.elements.indexed;
      final expand = controller.coral.elements.expand((e) => [e, e]);

      final termType = whereTypeInt.toTerminal(() {});
      final termIdx = indexed.toTerminal(() {});
      final termExp = expand.toTerminal(() {});

      termType.activate();
      termIdx.activate();
      termExp.activate();

      expect(termType.snapshot.data, [1, 2]);
      expect(termIdx.snapshot.data, [(0, 1), (1, 'a'), (2, 2), (3, 'b')]);
      expect(termExp.snapshot.data, [1, 1, 'a', 'a', 2, 2, 'b', 'b']);

      controller.set([3, 'c']);
      expect(termType.snapshot.data, [3]);
      expect(termIdx.snapshot.data, [(0, 3), (1, 'c')]);
      expect(termExp.snapshot.data, [3, 3, 'c', 'c']);

      termType.deactivate();
      termIdx.deactivate();
      termExp.deactivate();
    });

    test('reduce, fold, every, join, any, toList, toSet', () {
      final controller = CoralController<Iterable<int>>([1, 2, 3], broadcast: true);

      final sum = controller.coral.elements.reduce((val, el) => val + el);
      final foldedSum = controller.coral.elements.fold(10, (prev, el) => prev + el);
      final everyPositive = controller.coral.elements.every((x) => x > 0);
      final joined = controller.coral.elements.join('-');
      final anyEven = controller.coral.elements.any((x) => x % 2 == 0);
      final toList = controller.coral.elements.toList();
      final toSet = controller.coral.elements.toSet();

      final termSum = sum.toTerminal(() {});
      final termFold = foldedSum.toTerminal(() {});
      final termEvery = everyPositive.toTerminal(() {});
      final termJoin = joined.toTerminal(() {});
      final termAny = anyEven.toTerminal(() {});
      final termList = toList.toTerminal(() {});
      final termSet = toSet.toTerminal(() {});

      termSum.activate();
      termFold.activate();
      termEvery.activate();
      termJoin.activate();
      termAny.activate();
      termList.activate();
      termSet.activate();

      expect(termSum.snapshot.data, 6);
      expect(termFold.snapshot.data, 16);
      expect(termEvery.snapshot.data, true);
      expect(termJoin.snapshot.data, '1-2-3');
      expect(termAny.snapshot.data, true);
      expect(termList.snapshot.data, [1, 2, 3]);
      expect(termSet.snapshot.data, {1, 2, 3});

      controller.set([5, 7]);
      expect(termSum.snapshot.data, 12);
      expect(termFold.snapshot.data, 22);
      expect(termEvery.snapshot.data, true);
      expect(termJoin.snapshot.data, '5-7');
      expect(termAny.snapshot.data, false);

      termSum.deactivate();
      termFold.deactivate();
      termEvery.deactivate();
      termJoin.deactivate();
      termAny.deactivate();
      termList.deactivate();
      termSet.deactivate();
    });

    test('isEmpty, isNotEmpty, take, skip, elementAt', () {
      final controller = CoralController<Iterable<int>>([10, 20, 30], broadcast: true);

      final isEmpty = controller.coral.elements.isEmpty;
      final isNotEmpty = controller.coral.elements.isNotEmpty;
      final takeTwo = controller.coral.elements.take(2);
      final skipOne = controller.coral.elements.skip(1);
      final elementAtOne = controller.coral.elements.elementAt(1);

      final termEmpty = isEmpty.toTerminal(() {});
      final termNotEmpty = isNotEmpty.toTerminal(() {});
      final termTake = takeTwo.toTerminal(() {});
      final termSkip = skipOne.toTerminal(() {});
      final termElem = elementAtOne.toTerminal(() {});

      termEmpty.activate();
      termNotEmpty.activate();
      termTake.activate();
      termSkip.activate();
      termElem.activate();

      expect(termEmpty.snapshot.data, false);
      expect(termNotEmpty.snapshot.data, true);
      expect(termTake.snapshot.data, [10, 20]);
      expect(termSkip.snapshot.data, [20, 30]);
      expect(termElem.snapshot.data, 20);

      controller.set([]);
      expect(termEmpty.snapshot.data, true);
      expect(termNotEmpty.snapshot.data, false);

      termEmpty.deactivate();
      termNotEmpty.deactivate();
      termTake.deactivate();
      termSkip.deactivate();
      termElem.deactivate();
    });

    test('first, firstOrNull, last, lastOrNull, single, singleOrNull, lastWhere, singleWhere', () {
      final controller = CoralController<Iterable<int>>([1], broadcast: true);

      final first = controller.coral.elements.first;
      final firstOrNull = controller.coral.elements.firstOrNull;
      final last = controller.coral.elements.last;
      final lastOrNull = controller.coral.elements.lastOrNull;
      final single = controller.coral.elements.single;
      final singleOrNull = controller.coral.elements.singleOrNull;
      final lastWhere = controller.coral.elements.lastWhere((x) => x > 0);
      final singleWhere = controller.coral.elements.singleWhere((x) => x > 0);

      final termFirst = first.toTerminal(() {});
      final termFirstOrNull = firstOrNull.toTerminal(() {});
      final termLast = last.toTerminal(() {});
      final termLastOrNull = lastOrNull.toTerminal(() {});
      final termSingle = single.toTerminal(() {});
      final termSingleOrNull = singleOrNull.toTerminal(() {});
      final termLastWhere = lastWhere.toTerminal(() {});
      final termSingleWhere = singleWhere.toTerminal(() {});

      termFirst.activate();
      termFirstOrNull.activate();
      termLast.activate();
      termLastOrNull.activate();
      termSingle.activate();
      termSingleOrNull.activate();
      termLastWhere.activate();
      termSingleWhere.activate();

      expect(termFirst.snapshot.data, 1);
      expect(termFirstOrNull.snapshot.data, 1);
      expect(termLast.snapshot.data, 1);
      expect(termLastOrNull.snapshot.data, 1);
      expect(termSingle.snapshot.data, 1);
      expect(termSingleOrNull.snapshot.data, 1);
      expect(termLastWhere.snapshot.data, 1);
      expect(termSingleWhere.snapshot.data, 1);

      controller.set([]);
      expect(termFirstOrNull.snapshot.data, null);
      expect(termLastOrNull.snapshot.data, null);
      expect(termSingleOrNull.snapshot.data, null);

      termFirst.deactivate();
      termFirstOrNull.deactivate();
      termLast.deactivate();
      termLastOrNull.deactivate();
      termSingle.deactivate();
      termSingleOrNull.deactivate();
      termLastWhere.deactivate();
      termSingleWhere.deactivate();
    });
  });

  group('CoralListElements coverage', () {
    test('indexWhere, lastIndexWhere, lastIndexOf', () {
      final controller = CoralController<List<String>>(['a', 'b', 'a'], broadcast: true);

      final idxWhere = controller.coral.elements.indexWhere((x) => x == 'a');
      final lastIdxWhere = controller.coral.elements.lastIndexWhere((x) => x == 'a');
      final lastIdxOf = controller.coral.elements.lastIndexOf('a');

      final termIdxWhere = idxWhere.toTerminal(() {});
      final termLastIdxWhere = lastIdxWhere.toTerminal(() {});
      final termLastIdxOf = lastIdxOf.toTerminal(() {});

      termIdxWhere.activate();
      termLastIdxWhere.activate();
      termLastIdxOf.activate();

      expect(termIdxWhere.snapshot.data, 0);
      expect(termLastIdxWhere.snapshot.data, 2);
      expect(termLastIdxOf.snapshot.data, 2);

      controller.set(['x', 'y']);
      expect(termIdxWhere.snapshot.data, -1);
      expect(termLastIdxWhere.snapshot.data, -1);
      expect(termLastIdxOf.snapshot.data, -1);

      termIdxWhere.deactivate();
      termLastIdxWhere.deactivate();
      termLastIdxOf.deactivate();
    });
  });

  group('CoralSetElements coverage', () {
    test('lookup in Set reactively', () {
      final controller = CoralController<Set<String>>({'a', 'b'}, broadcast: true);

      final lookupA = controller.coral.elements.lookup('a');
      final lookupC = controller.coral.elements.lookup('c');

      final termA = lookupA.toTerminal(() {});
      final termC = lookupC.toTerminal(() {});

      termA.activate();
      termC.activate();

      expect(termA.snapshot.data, 'a');
      expect(termC.snapshot.data, null);

      controller.set({'c', 'd'});
      expect(termA.snapshot.data, null);
      expect(termC.snapshot.data, 'c');

      termA.deactivate();
      termC.deactivate();
    });
  });

  group('CoralMapElements coverage', () {
    test('containsValue, isEmpty, isNotEmpty', () {
      final controller = CoralController<Map<String, int>>({'a': 1}, broadcast: true);

      final containsVal1 = controller.coral.elements.containsValue(1);
      final containsVal2 = controller.coral.elements.containsValue(2);
      final isEmpty = controller.coral.elements.isEmpty;
      final isNotEmpty = controller.coral.elements.isNotEmpty;

      final termContains1 = containsVal1.toTerminal(() {});
      final termContains2 = containsVal2.toTerminal(() {});
      final termEmpty = isEmpty.toTerminal(() {});
      final termNotEmpty = isNotEmpty.toTerminal(() {});

      termContains1.activate();
      termContains2.activate();
      termEmpty.activate();
      termNotEmpty.activate();

      expect(termContains1.snapshot.data, true);
      expect(termContains2.snapshot.data, false);
      expect(termEmpty.snapshot.data, false);
      expect(termNotEmpty.snapshot.data, true);

      controller.set({});
      expect(termContains1.snapshot.data, false);
      expect(termEmpty.snapshot.data, true);
      expect(termNotEmpty.snapshot.data, false);

      termContains1.deactivate();
      termContains2.deactivate();
      termEmpty.deactivate();
      termNotEmpty.deactivate();
    });
  });
}
