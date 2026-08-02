// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline/coralline.dart';
import 'package:test/test.dart';

void main() {
  group('Coral List Elements Instance Methods Tests', () {
    test('elements.toList converts Coral<Iterable<T>> into Coral<List<T>>', () {
      final setController = CoralController<Set<int>>({1, 2, 3});

      final listCoralProxy = setController.coral.elements.toList();
      final proxyTerminal = listCoralProxy.toTerminal(() {});

      proxyTerminal.activate();

      expect(proxyTerminal.snapshot.data, equals([1, 2, 3]));
      expect(() => proxyTerminal.snapshot.data.add(4), throwsUnsupportedError);

      setController.set({10, 20});
      expect(proxyTerminal.snapshot.data, equals([10, 20]));

      proxyTerminal.deactivate();
    });

    test('elements.cast downcasts dynamic iterable into Coral<List<T>>', () {
      final dynamicListController = CoralController<List<dynamic>>(['a', 'b', 'c']);

      final stringListCoralProxy = dynamicListController.coral.elements.cast<String>();
      final proxyTerminal = stringListCoralProxy.toTerminal(() {});

      proxyTerminal.activate();

      expect(proxyTerminal.snapshot.data, equals(['a', 'b', 'c']));

      proxyTerminal.deactivate();
    });

    test('elements.cast adapts List<S> to List<T>', () {
      final numListController = CoralController<List<num>>([1, 2, 3]);

      final castProxyCoral = numListController.coral.elements.cast<int>();
      final proxyTerminal = castProxyCoral.toTerminal(() {});

      proxyTerminal.activate();

      expect(proxyTerminal.snapshot.data, equals([1, 2, 3]));

      numListController.set([10, 20]);
      expect(proxyTerminal.snapshot.data, equals([10, 20]));

      proxyTerminal.deactivate();
    });
  });
}
