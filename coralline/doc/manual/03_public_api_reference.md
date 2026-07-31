# 📖 Coralline Public API Reference Manual

This document serves as the complete reference catalog for all **Classes**, **Mixins**, **Extensions**, and **Exceptions** exported by `package:coralline/coralline.dart`.

<br><br>

### 1. Core Classes

### `CoralController<T>`
- **Role**: Imperative data source node. Injects external data into the pipeline.
- **Key Constructors**:
  - `CoralController(T initialValue, {bool broadcast = false, ...})`: Standard controller.
  - `CoralController.lateLifecycle({bool broadcast = false, ...})`: Computes/provides data upon activation without initial value.
- **Key Methods**:
  - `set(T value)`: Injects new data (publishes Push-Dirty notification).
  - `setGuarded(T Function() producer)`: Executes callback and converts thrown errors to Damaged snapshots.

### `Coral<T>`
- **Role**: Read-only lazy computation pipeline node.
- **Key Properties**:
  - `.data`: Returns computed data (throws if Empty or Damaged).
  - `.dataOrNull`: Returns data if valid, otherwise `null`.
  - `.snapshot`: Returns current boxed `CoralSnapshot<T>`.
- **Key Pipeline Operators**:
  - `.map<R>(R Function(T) mapper)`: Synchronous transformation node.
  - `.cascade<R>(Coral<R> Function(T) cascade, {bool seal, bool hotswap, bool eager})`: 1:1 dynamic pipeline swapping node.
  - `.diverge<R>(Iterable<Coral<R>> Function(T) cascade, {bool seal, bool hotswap, bool eager})`: 1:N dynamic topological divergence node yielding a `Trunk<R>`.
  - `.converge<R>(Coral<R> Function(Iterable<Coral<T>>) cascade)`: N:1 dynamic topological convergence node.
  - `.combine<O, R>(Coral<O> other, R Function(T, O) combiner)`: Combines 2 pipeline nodes.
  - `.guard({bool Function()? canProceed})`: Wraps node with an encapsulated state guard shield to prevent `Empty`-to-`Damaged` extraction explosions.
  - `.toTerminal(onDirty)`: Connects a terminal subscriber.
  - `.broadcast()`: Converts 1:1 pipeline to 1:N broadcaster node.

### `CoralComputation<T>`
- **Role**: Base class defining pure lazy computation logic.
- **Subclasses**:
  - `SimplexComputation<T>`: Single inbound node.
  - `ComplexComputation<T>`: Multiple inbound nodes.

### `CoralBroadcaster<T>`
- **Role**: Safely shares a single `Coral` pipeline across multiple subscribers (1:N branching).

### `CoralCoupler<T>`
- **Role**: Dynamically swaps observed target pipeline node at runtime.

### `CoralTerminal<T>`
- **Role**: Final destination node (typically bound to Flutter Widget build cycle).
- **Key Methods**:
  - `activate()`: Connects to upstream topology and starts listening for dirty flags.
  - `deactivate()`: Unbinds terminal from upstream topology to prevent memory leaks.

### `CoralSnapshot<T>`
- **Role**: Immutable struct data box (`CoralSnapshotValid`, `CoralSnapshotEmpty`, `CoralSnapshotDamaged`).

<br><br>

### 2. Public Mixins

- `CoralSnapshotDelegator<T>`: Delegates snapshot getters (`.data`, `.snapshot`).
- `CorallineLifecycleAware`: Listens for node activation and deactivation events.

<br><br>

### 3. Public Extensions

- `ListCoralElementsExtension`, `SetCoralElementsExtension`, `MapCoralElementsExtension`, `IterableCoralElementsExtension`: Collection pipeline utilities.
- `AsyncCoralExtension`, `AsyncTrunkExtension`: Asynchronous mapping and debouncing.
- `CoralCollectionExtension`: Combines list of coral nodes (`combineAll`).
- `CorallineDebugExtension`: Prints ASCII DAG tree representation (`.toDebugString()`).

<br><br>

### 4. Public Exceptions & Errors

- `CorallineException`: Root exception class.
- `CoralNodeReleaseViolationException`: Thrown on 1:1 pipeline violation.
- `CoralSnapshotExtractionException`: Thrown when extracting data from empty/damaged snapshot.
- `CoralNodeReentrancyError`: Thrown on circular cycle or re-entrancy detection.
