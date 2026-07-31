import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coralline_flutter/coralline_flutter.dart';

// Custom Listenable to test distinct behavior without ValueNotifier's built-in distinct logic
class CustomListenable<T> extends ChangeNotifier implements ValueListenable<T> {
  CustomListenable(this._value);
  
  T _value;
  
  @override
  T get value => _value;
  
  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }
}

void main() {
  group('value_listenable.dart - ValueListenableCoralExtension', () {
    test('Subscription lifecycle (Activate/Deactivate)', () {
      final notifier = ValueNotifier<int>(0);
      final coral = notifier.toCoral();
      
      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, false);
      
      // Activate
      final terminal = CoralTerminal(coral, onDirty: () {});
      terminal.activate();
      
      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, true);
      
      // Deactivate
      terminal.deactivate();
      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, false);
    });

    test('Value updates and state propagation', () {
      final notifier = ValueNotifier<String>('A');
      final coral = notifier.toCoral();
      
      final emittedValues = <String>[];
      final terminal = CoralTerminal(coral, onDirty: () {
        emittedValues.add(coral.data);
      });
      terminal.activate();
      
      expect(emittedValues, ['A']);
      
      notifier.value = 'B';
      expect(emittedValues, ['A', 'B']);
      
      notifier.value = 'C';
      expect(emittedValues, ['A', 'B', 'C']);
      
      terminal.deactivate();
    });

    test('Distinct behavior (true by default)', () {
      final listenable = CustomListenable<int>(1);
      final coral = listenable.toCoral(); // distinct: true
      
      final emittedValues = <int>[];
      final terminal = CoralTerminal(coral, onDirty: () {
        emittedValues.add(coral.data);
      });
      terminal.activate();
      
      expect(emittedValues, [1]);
      
      listenable.value = 1; // Notifies, but Coral should distinct it
      expect(emittedValues, [1]);
      
      listenable.value = 2;
      expect(emittedValues, [1, 2]);
      
      terminal.deactivate();
    });

    test('Distinct behavior (false)', () {
      final listenable = CustomListenable<int>(1);
      final coral = listenable.toCoral(distinct: false);
      
      final emittedValues = <int>[];
      final terminal = CoralTerminal(coral, onDirty: () {
        emittedValues.add(coral.data);
      });
      terminal.activate();
      
      expect(emittedValues, [1]);
      
      listenable.value = 1; // Notifies, and Coral should NOT distinct it
      expect(emittedValues, [1, 1]);
      
      listenable.value = 2;
      expect(emittedValues, [1, 1, 2]);
      
      terminal.deactivate();
    });

    test('Distinct behavior with custom equals', () {
      final listenable = CustomListenable<int>(1);
      final coral = listenable.toCoral(
        equals: (a, b) => a % 2 == b % 2,
      );
      
      final emittedValues = <int>[];
      final terminal = CoralTerminal(coral, onDirty: () {
        emittedValues.add(coral.data);
      });
      terminal.activate();
      
      expect(emittedValues, [1]);
      
      listenable.value = 3; 
      expect(emittedValues, [1]);
      
      listenable.value = 2; 
      expect(emittedValues, [1, 2]);
      
      listenable.value = 4; 
      expect(emittedValues, [1, 2]);
      
      terminal.deactivate();
    });

    test('Nullable ValueNotifier handling (null -> value -> null)', () {
      final notifier = ValueNotifier<int?>(null);
      final coral = notifier.toCoral();

      final emittedValues = <int?>[];
      final terminal = CoralTerminal(coral, onDirty: () {
        emittedValues.add(coral.data);
      });
      terminal.activate();

      expect(emittedValues, [null]);

      notifier.value = 42;
      expect(emittedValues, [null, 42]);

      notifier.value = null;
      expect(emittedValues, [null, 42, null]);

      terminal.deactivate();
    });

    test('Multiple activation and deactivation cycles', () {
      final notifier = ValueNotifier<String>('Initial');
      final coral = notifier.toCoral();

      final terminal = CoralTerminal(coral, onDirty: () {});

      terminal.activate();
      expect(coral.data, 'Initial');
      terminal.deactivate();

      notifier.value = 'Updated While Dormant';

      terminal.activate();
      expect(coral.data, 'Updated While Dormant');
      terminal.deactivate();
    });
  });
}

