# Coralline Extensions

The official extension library for the [Coralline](https://pub.dev/packages/coralline) framework. Seamlessly integrates Dart's `Future`, `Stream`, and `Iterable` into the `CoralNode` declarative pipeline architecture.

<br>

---

<br>

## Features

- **`Future.toCoral()`**: Transforms any Dart `Future` into a reactive `Coral` node.
- **`Stream.toCoral()`**: Transforms any Dart `Stream` into a reactive `Coral` node.
- **`Iterable.toTrunk()`**: Bundles multiple Futures or Streams into a single, lifecycle-managed `Trunk`.

<br>

---

<br>

## The Magic of Lazy Lifecycles

Bridging `Future` and `Stream` directly into a UI pipeline often introduces memory leaks or unnecessary background computations. `coralline_extensions` solves this using the "Push-Dirty, Pull-Data" architecture of the `CoralNode` framework:

### 1. Lazy Computation
Standard Dart `Future.then()` or `Stream.listen()` execute eagerly. This extension library defers all subscriptions until the resulting `Coral` pipeline is actually **Active** (e.g., when a UI component attaches a `CoralTerminal`). If the terminal is never activated, the data is never fetched.

### 2. Auto-Cleanup (Zero Memory Leaks)
When a `CoralTerminal` is deactivated (e.g., when a Flutter widget is disposed), the underlying `Stream` subscription is **automatically cancelled**. You no longer need to manually manage `StreamSubscription` objects.

### 3. Fail-Fast Safety
If a `Future` or `Stream` emits an error, it is automatically captured and safely converted into a `CoralSnapshot.damaged` state. This physically prevents corrupted or missing data from progressing further down the pipeline.

<br>

---

<br>

## Quick Start

```dart
import 'dart:async';
import 'package:coralline_extensions/async.dart';

void main() {
  // 1. Convert a Stream to a Coral (Supports distinct and custom equality)
  final streamController = StreamController<int>();
  final streamCoral = streamController.stream.toCoral(distinct: true);

  // 2. Attach a terminal. 
  // THIS is the exact moment the stream actually gets subscribed to!
  final terminal = streamCoral.toTerminal(() {
    print("UI should rebuild! New data: ${streamCoral.data}");
  });
  terminal.activate();

  // 3. Push data
  streamController.add(100);

  // 4. Cleanup 
  // (Automatically unsubscribes from the Stream, preventing memory leaks!)
  terminal.deactivate();
}
```
