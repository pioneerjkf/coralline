# Coralline Public API Reference Manual

This document summarizes selected APIs exported by `package:coralline/coralline.dart`; it is not a complete catalog. For exact signatures and the full API surface, refer to the generated Dart API documentation.

<br><br>

### 1. Core Classes

### `CoralController<T>`
- **Role**: Imperative data source node. Injects external data into the pipeline.
- **Key Constructors**:
  - `CoralController(T initialValue, {bool broadcast = false, ...})`: Standard controller.
  - `CoralController.lateLifecycle({bool broadcast = false, ...})`: Starts without an initial value and accepts lifecycle callbacks.
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
  - `.combine<O, R>(Coral<O> other, R Function(T, O) combiner)`: Combines 2 pipeline nodes.
  - `.guard({bool Function()? canProceed})`: Adds a condition for whether the guarded computation can proceed.
  - `.toTerminal(onDirty)`: Connects a terminal subscriber.
  - `.toBroadcaster()`: Converts 1:1 pipeline to 1:N broadcaster node.

### `Trunk<T>`
- **Role**: Topological bundle of `Coral` nodes.
- **Key Methods & Operators**:
  - `.aggregate<R>(R Function(Iterable<Coral<T>>) aggregator)`: Aggregates multiple `Coral` lines into a single scalar computation node.
  - `.combine()`: Combines all lines into a `List<T>`.
  - `.converge<R>(Coral<R> Function(Iterable<Coral<T>>) cascade, {bool seal, bool hotswap, bool eager})`: N:1 dynamic topological convergence node.

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
  - `deactivate()`: Ends observation and releases the terminal's upstream connection.

### `CoralSnapshot<T>`
- **Role**: Immutable value wrapper with valid, empty, and damaged variants (`CoralSnapshotValid`, `CoralSnapshotEmpty`, `CoralSnapshotDamaged`).

<br><br>

### 2. Public Mixins

- `CoralSnapshotDelegator<T>`: Delegates snapshot getters (`.data`, `.snapshot`).
- `CorallineLifecycleAware`: Listens for node activation and deactivation events.

<br><br>

### 3. Public Extensions

- `ListCoralElementsExtension`, `SetCoralElementsExtension`, `MapCoralElementsExtension`, `IterableCoralElementsExtension`: Collection pipeline utilities.
- `FutureCoralExtension`, `FutureCollectionTrunkExtension`, `StreamCoralExtension`, `StreamControllerCoralExtension`, `StreamCollectionTrunkExtension`: Asynchronous mapping and stream integration.
- `CoralCollectionExtension`: Combines list of coral nodes (`combineAll`).
- `CorallineDebugExtension`: Prints ASCII DAG tree representation (`.toDebugString()`).

<br><br>

### 4. Public Exceptions & Errors

- `CorallineException`: Root exception class.
- `CoralNodeReleaseViolationException`: Thrown on 1:1 pipeline violation.
- `CoralSnapshotExtractionException`: Thrown when extracting data from empty/damaged snapshot.
- `CoralNodeReentrancyError`: Thrown on circular cycle or re-entrancy detection.
