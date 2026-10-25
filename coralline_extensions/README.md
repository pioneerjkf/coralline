# Coralline Extensions

The official extension library for the [Coralline](https://pub.dev/packages/coralline) framework, bringing reactive pipeline operations to Dart collections and iterables.

---

## Features

`coralline_extensions` enhances `Coral<Iterable<E>>` and `Coral<List<E>>` nodes with reactive collection pipelines via the `.elements` proxy:

- **Aggregations & Statistics**:
  - `coral.elements.sum`: Reactively computes the sum of `num`, `int`, or `double` collections.
  - `coral.elements.average`: Reactively computes the arithmetic mean.
- **Comparable Extrema**:
  - `coral.elements.minOrNull`: Reactively tracks the minimum element.
  - `coral.elements.maxOrNull`: Reactively tracks the maximum element.
- **Transformations & Filtering**:
  - `coral.elements.where(predicate)`: Reactive filtering pipeline node.
  - `coral.elements.map(transform)`: Reactive projection pipeline node.
  - `coral.elements.firstWhereOrNull(test)`: Safe search yielding `null` when not found.
- **List Operations**:
  - `coral.elements.sorted([compare])`: Reactively maintains a sorted view.
  - `coral.elements.binarySearch(element, [compare])`: Binary search over sorted collections.
  - `coral.elements.lowerBound(element, [compare])`: Lower bound search index.

---

## Installation

Add `coralline` and `coralline_extensions` to your `pubspec.yaml`:

```yaml
dependencies:
  coralline: ^0.1.4
  coralline_extensions: ^0.1.4
```

---

## Quick Start

```dart
import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/coralline_extensions.dart';

void main() {
  // 1. Create a reactive controller holding a collection of numbers (with broadcast enabled for multiple subscribers)
  final numbersController =
      CoralController<List<double>>([10.0, 20.0, 30.0], broadcast: true);

  // 2. Use coralline_extensions to calculate reactive sum and average
  final sumCoral = numbersController.coral.elements.sum;
  final avgCoral = numbersController.coral.elements.average;

  // 3. Attach terminals to listen and pull data
  final sumTerminal = sumCoral.toTerminal(() {});
  final avgTerminal = avgCoral.toTerminal(() {});

  sumTerminal.activate();
  avgTerminal.activate();

  print('Sum: ${sumTerminal.data}'); // 60.0
  print('Average: ${avgTerminal.data}'); // 20.0

  // 4. Update collection reactively
  numbersController.set([5.0, 15.0, 25.0, 35.0]);

  print('Updated Sum: ${sumTerminal.data}'); // 80.0
  print('Updated Average: ${avgTerminal.data}'); // 20.0

  // Cleanup
  sumTerminal.deactivate();
  avgTerminal.deactivate();
}
```

---

## License

This project is licensed under the Apache License, Version 2.0. See the LICENSE file for details.
