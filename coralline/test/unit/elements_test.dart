// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('elements.dart Comprehensive Unit Tests', () {
    group('CoralIterableElements Tests', () {
      test('map, where, whereType, indexed, expand', () {
        final c1 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tMap = c1.elements.map((e) => e * 2).toTerminal(() {});

        final c2 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tWhere = c2.elements.where((e) => e > 2).toTerminal(() {});

        final c3 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tWhereType = c3.elements.whereType<double>().toTerminal(() {});

        final c4 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tIndexed = c4.elements.indexed.toTerminal(() {});

        final c5 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tExpand = c5.elements.expand((e) => [e, e]).toTerminal(() {});

        tMap.activate();
        tWhere.activate();
        tWhereType.activate();
        tIndexed.activate();
        tExpand.activate();

        expect(tMap.snapshot.data, [2, 5, 6, 8, 10]);
        expect(tWhere.snapshot.data, [2.5, 3, 4, 5]);
        expect(tWhereType.snapshot.data, [2.5]);
        expect(tIndexed.snapshot.data.map((p) => '${p.$1}:${p.$2}').toList(), ['0:1', '1:2.5', '2:3', '3:4', '4:5']);
        expect(tExpand.snapshot.data, [1, 1, 2.5, 2.5, 3, 3, 4, 4, 5, 5]);

        tMap.deactivate();
        tWhere.deactivate();
        tWhereType.deactivate();
        tIndexed.deactivate();
        tExpand.deactivate();
      });

      test('contains, reduce, fold, every, join, any, toList, toSet', () {
        final c1 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tContains = c1.elements.contains(3).toTerminal(() {});

        final c2 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tReduce = c2.elements.reduce((a, b) => a + b).toTerminal(() {});

        final c3 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tFold = c3.elements.fold<num>(10, (a, b) => a + b).toTerminal(() {});

        final c4 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tEvery = c4.elements.every((e) => e > 0).toTerminal(() {});

        final c5 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tJoin = c5.elements.join('-').toTerminal(() {});

        final c6 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tAny = c6.elements.any((e) => e == 5).toTerminal(() {});

        final c7 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tToList = c7.elements.toList().toTerminal(() {});

        final c8 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tToSet = c8.elements.toSet().toTerminal(() {});

        tContains.activate();
        tReduce.activate();
        tFold.activate();
        tEvery.activate();
        tJoin.activate();
        tAny.activate();
        tToList.activate();
        tToSet.activate();

        expect(tContains.snapshot.data, isTrue);
        expect(tReduce.snapshot.data, 15.5);
        expect(tFold.snapshot.data, 25.5);
        expect(tEvery.snapshot.data, isTrue);
        expect(tJoin.snapshot.data, '1-2.5-3-4-5');
        expect(tAny.snapshot.data, isTrue);
        expect(tToList.snapshot.data, [1, 2.5, 3, 4, 5]);
        expect(tToSet.snapshot.data, {1, 2.5, 3, 4, 5});

        tContains.deactivate();
        tReduce.deactivate();
        tFold.deactivate();
        tEvery.deactivate();
        tJoin.deactivate();
        tAny.deactivate();
        tToList.deactivate();
        tToSet.deactivate();
      });

      test('length, isEmpty, isNotEmpty, take, skip, first, firstOrNull, last, lastOrNull, elementAt', () {
        final c1 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tLength = c1.elements.length.toTerminal(() {});

        final c2 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tIsEmpty = c2.elements.isEmpty.toTerminal(() {});

        final c3 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tIsNotEmpty = c3.elements.isNotEmpty.toTerminal(() {});

        final c4 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tTake = c4.elements.take(2).toTerminal(() {});

        final c5 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tSkip = c5.elements.skip(3).toTerminal(() {});

        final c6 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tFirst = c6.elements.first.toTerminal(() {});

        final c7 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tFirstOrNull = c7.elements.firstOrNull.toTerminal(() {});

        final c8 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tLast = c8.elements.last.toTerminal(() {});

        final c9 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tLastOrNull = c9.elements.lastOrNull.toTerminal(() {});

        final c10 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tFirstWhere = c10.elements.firstWhere((e) => e > 2).toTerminal(() {});

        final c11 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tLastWhere = c11.elements.lastWhere((e) => e < 4).toTerminal(() {});

        final c12 = Coral<Iterable<num>>.data([1, 2.5, 3, 4, 5]);
        final tElementAt = c12.elements.elementAt(1).toTerminal(() {});

        tLength.activate();
        tIsEmpty.activate();
        tIsNotEmpty.activate();
        tTake.activate();
        tSkip.activate();
        tFirst.activate();
        tFirstOrNull.activate();
        tLast.activate();
        tLastOrNull.activate();
        tFirstWhere.activate();
        tLastWhere.activate();
        tElementAt.activate();

        expect(tLength.snapshot.data, 5);
        expect(tIsEmpty.snapshot.data, isFalse);
        expect(tIsNotEmpty.snapshot.data, isTrue);
        expect(tTake.snapshot.data, [1, 2.5]);
        expect(tSkip.snapshot.data, [4, 5]);
        expect(tFirst.snapshot.data, 1);
        expect(tFirstOrNull.snapshot.data, 1);
        expect(tLast.snapshot.data, 5);
        expect(tLastOrNull.snapshot.data, 5);
        expect(tFirstWhere.snapshot.data, 2.5);
        expect(tLastWhere.snapshot.data, 3);
        expect(tElementAt.snapshot.data, 2.5);

        tLength.deactivate();
        tIsEmpty.deactivate();
        tIsNotEmpty.deactivate();
        tTake.deactivate();
        tSkip.deactivate();
        tFirst.deactivate();
        tFirstOrNull.deactivate();
        tLast.deactivate();
        tLastOrNull.deactivate();
        tFirstWhere.deactivate();
        tLastWhere.deactivate();
        tElementAt.deactivate();
      });

      test('single, singleOrNull, singleWhere', () {
        final cSingle = Coral.data([42]);

        final tSingle = cSingle.elements.single.toTerminal(() {});
        final c2 = Coral.data([42]);
        final tSingleOrNull = c2.elements.singleOrNull.toTerminal(() {});
        final c3 = Coral.data([42]);
        final tSingleWhere = c3.elements.singleWhere((e) => e == 42).toTerminal(() {});

        tSingle.activate();
        tSingleOrNull.activate();
        tSingleWhere.activate();

        expect(tSingle.snapshot.data, 42);
        expect(tSingleOrNull.snapshot.data, 42);
        expect(tSingleWhere.snapshot.data, 42);

        tSingle.deactivate();
        tSingleOrNull.deactivate();
        tSingleWhere.deactivate();
      });
    });

    group('CoralListElements Tests', () {
      test('List element operators and methods', () {
        final c1 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tIndex = c1.elements[1].toTerminal(() {});

        final c2 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tReversed = c2.elements.reversed.toTerminal(() {});

        final c3 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tIndexOf = c3.elements.indexOf(20).toTerminal(() {});

        final c4 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tIndexWhere = c4.elements.indexWhere((e) => e > 25).toTerminal(() {});

        final c5 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tLastIndexWhere = c5.elements.lastIndexWhere((e) => e == 20).toTerminal(() {});

        final c6 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tLastIndexOf = c6.elements.lastIndexOf(20).toTerminal(() {});

        final c7 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tSublist = c7.elements.sublist(1, 4).toTerminal(() {});

        final c8 = Coral<List<int>>.data([10, 20, 30, 20, 40]);
        final tAsMap = c8.elements.asMap().toTerminal(() {});

        final c9 = Coral<List<num>>.data([10, 20, 30]);
        final tCast = c9.elements.cast<int>().toTerminal(() {});

        final c10 = Coral<List<int>>.data([10, 20, 30]);
        final tUnmodifiable = c10.elements.toUnmodifiable().toTerminal(() {});

        tIndex.activate();
        tReversed.activate();
        tIndexOf.activate();
        tIndexWhere.activate();
        tLastIndexWhere.activate();
        tLastIndexOf.activate();
        tSublist.activate();
        tAsMap.activate();
        tCast.activate();
        tUnmodifiable.activate();

        expect(tIndex.snapshot.data, 20);
        expect(tReversed.snapshot.data, [40, 20, 30, 20, 10]);
        expect(tIndexOf.snapshot.data, 1);
        expect(tIndexWhere.snapshot.data, 2);
        expect(tLastIndexWhere.snapshot.data, 3);
        expect(tLastIndexOf.snapshot.data, 3);
        expect(tSublist.snapshot.data, [20, 30, 20]);
        expect(tAsMap.snapshot.data, {0: 10, 1: 20, 2: 30, 3: 20, 4: 40});
        expect(tCast.snapshot.data, [10, 20, 30]);
        expect(tUnmodifiable.snapshot.data, [10, 20, 30]);
        expect(() => tUnmodifiable.snapshot.data[0] = 99, throwsUnsupportedError);

        tIndex.deactivate();
        tReversed.deactivate();
        tIndexOf.deactivate();
        tIndexWhere.deactivate();
        tLastIndexWhere.deactivate();
        tLastIndexOf.deactivate();
        tSublist.deactivate();
        tAsMap.deactivate();
        tCast.deactivate();
        tUnmodifiable.deactivate();
      });
    });

    group('CoralSetElements Tests', () {
      test('Set element lookup, intersection, union, difference', () {
        final c1 = Coral<Set<int>>.data({1, 2, 3, 4});
        final tLookup = c1.elements.lookup(3).toTerminal(() {});

        final c2 = Coral<Set<int>>.data({1, 2, 3, 4});
        final tIntersection = c2.elements.intersection({3, 4, 5}).toTerminal(() {});

        final c3 = Coral<Set<int>>.data({1, 2, 3, 4});
        final tUnion = c3.elements.union({4, 5, 6}).toTerminal(() {});

        final c4 = Coral<Set<int>>.data({1, 2, 3, 4});
        final tDifference = c4.elements.difference({1, 2}).toTerminal(() {});

        final c5 = Coral<Set<num>>.data({1, 2, 3});
        final tCastSet = c5.elements.cast<int>().toTerminal(() {});

        final c6 = Coral<Set<int>>.data({1, 2, 3});
        final tUnmodifiableSet = c6.elements.toUnmodifiable().toTerminal(() {});

        tLookup.activate();
        tIntersection.activate();
        tUnion.activate();
        tDifference.activate();
        tCastSet.activate();
        tUnmodifiableSet.activate();

        expect(tLookup.snapshot.data, 3);
        expect(tIntersection.snapshot.data, {3, 4});
        expect(tUnion.snapshot.data, {1, 2, 3, 4, 5, 6});
        expect(tDifference.snapshot.data, {3, 4});
        expect(tCastSet.snapshot.data, {1, 2, 3});
        expect(tUnmodifiableSet.snapshot.data, {1, 2, 3});
        expect(() => tUnmodifiableSet.snapshot.data.add(4), throwsUnsupportedError);

        tLookup.deactivate();
        tIntersection.deactivate();
        tUnion.deactivate();
        tDifference.deactivate();
        tCastSet.deactivate();
        tUnmodifiableSet.deactivate();
      });
    });

    group('CoralMapElements Tests', () {
      test('Map element getters, operators and methods', () {
        final source = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final mapElements = source.elements;

        expect(mapElements.coral, isA<Coral<Map<String, int>>>());

        final c1 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tSubscript = c1.elements['b'].toTerminal(() {});

        final c2 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tContainsKey = c2.elements.containsKey('a').toTerminal(() {});

        final c3 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tContainsValue = c3.elements.containsValue(3).toTerminal(() {});

        final c4 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tMap = c4.elements.map((k, v) => MapEntry(k.toUpperCase(), v * 10)).toTerminal(() {});

        final c5 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tWhere = c5.elements.where((k, v) => v > 1).toTerminal(() {});

        final c6 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tKeys = c6.elements.keys.toTerminal(() {});

        final c7 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tValues = c7.elements.values.toTerminal(() {});

        final c8 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tLength = c8.elements.length.toTerminal(() {});

        final c9 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tIsEmpty = c9.elements.isEmpty.toTerminal(() {});

        final c10 = Coral<Map<String, int>>.data({'a': 1, 'b': 2, 'c': 3});
        final tIsNotEmpty = c10.elements.isNotEmpty.toTerminal(() {});

        tSubscript.activate();
        tContainsKey.activate();
        tContainsValue.activate();
        tMap.activate();
        tWhere.activate();
        tKeys.activate();
        tValues.activate();
        tLength.activate();
        tIsEmpty.activate();
        tIsNotEmpty.activate();

        final c11 = Coral<Map<String, num>>.data({'a': 1, 'b': 2});
        final tCastMap = c11.elements.cast<String, int>().toTerminal(() {});

        final c12 = Coral<Map<String, int>>.data({'a': 1, 'b': 2});
        final tUnmodifiableMap = c12.elements.toUnmodifiable().toTerminal(() {});

        tSubscript.activate();
        tContainsKey.activate();
        tContainsValue.activate();
        tMap.activate();
        tWhere.activate();
        tKeys.activate();
        tValues.activate();
        tLength.activate();
        tIsEmpty.activate();
        tIsNotEmpty.activate();
        tCastMap.activate();
        tUnmodifiableMap.activate();

        expect(tSubscript.snapshot.data, 2);
        expect(tContainsKey.snapshot.data, isTrue);
        expect(tContainsValue.snapshot.data, isTrue);
        expect(tMap.snapshot.data, {'A': 10, 'B': 20, 'C': 30});
        expect(tWhere.snapshot.data, {'b': 2, 'c': 3});
        expect(tKeys.snapshot.data, ['a', 'b', 'c']);
        expect(tValues.snapshot.data, [1, 2, 3]);
        expect(tLength.snapshot.data, 3);
        expect(tIsEmpty.snapshot.data, isFalse);
        expect(tIsNotEmpty.snapshot.data, isTrue);
        expect(tCastMap.snapshot.data, {'a': 1, 'b': 2});
        expect(tUnmodifiableMap.snapshot.data, {'a': 1, 'b': 2});
        expect(() => tUnmodifiableMap.snapshot.data['c'] = 3, throwsUnsupportedError);

        tSubscript.deactivate();
        tContainsKey.deactivate();
        tContainsValue.deactivate();
        tMap.deactivate();
        tWhere.deactivate();
        tKeys.deactivate();
        tValues.deactivate();
        tLength.deactivate();
        tIsEmpty.deactivate();
        tIsNotEmpty.deactivate();
        tCastMap.deactivate();
        tUnmodifiableMap.deactivate();
      });
    });

    group('CoralKeyedIterableElements Tests', () {
      test('keyed.map maintains cached instance for identical keys', () {
        int convertCount = 0;
        final controller = CoralController<List<Map<String, String>>>([
          {'id': '1', 'name': 'Item1'},
          {'id': '2', 'name': 'Item2'},
        ]);

        final mapped = controller.coral.keyed.map(
          key: (item) => item['id']!,
          convert: (item) {
            convertCount++;
            return 'Obj_${item['name']}';
          },
        );

        final terminal = mapped.toTerminal(() {});
        terminal.activate();

        expect(mapped.data, ['Obj_Item1', 'Obj_Item2']);
        expect(convertCount, 2);

        // Update list with same keys -> convert is NOT called again
        controller.set([
          {'id': '1', 'name': 'Item1_Updated'},
          {'id': '2', 'name': 'Item2_Updated'},
        ]);

        expect(mapped.data, ['Obj_Item1', 'Obj_Item2'], reason: 'Reuses cached objects for unchanged keys');
        expect(convertCount, 2);

        terminal.deactivate();
      });

      test('keyed.diverge 8 switch combinations (seal x hotswap x eager)', () {
        final source = Coral.data([1, 2]);

        final tr1 =
            source.keyed.diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: true, hotswap: true, eager: true);
        final tr2 =
            source.keyed.diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: true, hotswap: true, eager: false);
        final tr3 =
            source.keyed.diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: true, hotswap: false, eager: true);
        final tr4 = source.keyed
            .diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: true, hotswap: false, eager: false);
        final tr5 =
            source.keyed.diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: false, hotswap: true, eager: true);
        final tr6 = source.keyed
            .diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: false, hotswap: true, eager: false);
        final tr7 = source.keyed
            .diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: false, hotswap: false, eager: true);
        final tr8 = source.keyed
            .diverge(key: (i) => i, builder: (i) => Coral.data(i), seal: false, hotswap: false, eager: false);

        expect(tr1.runtimeType.toString(), contains('_SealedHotswapEagerKeyedDivergingTrunk'));
        expect(tr2.runtimeType.toString(), contains('_SealedHotswapLazyKeyedDivergingTrunk'));
        expect(tr3.runtimeType.toString(), contains('_SealedColdswapEagerKeyedDivergingTrunk'));
        expect(tr4.runtimeType.toString(), contains('_SealedColdswapLazyKeyedDivergingTrunk'));
        expect(tr5.runtimeType.toString(), contains('_DetachableHotswapEagerKeyedDivergingTrunk'));
        expect(tr6.runtimeType.toString(), contains('_DetachableHotswapLazyKeyedDivergingTrunk'));
        expect(tr7.runtimeType.toString(), contains('_DetachableColdswapEagerKeyedDivergingTrunk'));
        expect(tr8.runtimeType.toString(), contains('_DetachableColdswapLazyKeyedDivergingTrunk'));

        final term = tr1.toTerminal(() {});
        term.activate();
        expect(tr1.lines.map((c) => c.data).toList(), [1, 2]);
        term.deactivate();
      });
    });
  });
}
