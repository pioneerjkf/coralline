# Coralline Flutter (Coralline) Architecture Deep Dive

The Coralline Flutter (and its core engine, Coralline) framework is a **next-generation reactive framework** designed to overcome the limitations of common legacy state management models (MVC, MVP, MVVM). The core architecture penetrating this framework is a combination of the **MVI (Model-View-Intent)** philosophy and a **Topological Reactive DAG (Directed Acyclic Graph)**.

This document deeply analyzes what model the Coralline Flutter framework is based on, and how it structurally differs from existing models.

---

## 1. Architectural Identity: MVI + Topological DAG

Coralline Flutter goes beyond the limits of MVVM, which simply binds data to Views. Instead of a massive `ViewModel` object monopolizing and shaking up all the state, the entire process from the data wellspring to the screen rendering is structured as a finely divided pipeline taking the form of a **Directed Acyclic Graph (DAG)**.

### 1.1 Topology-based Node Tree (Topological Reactive DAG)
The Coralline Flutter pipeline is a topological graph consisting of the following key nodes. (This model shares the same trajectory as React's `Recoil`, `Jotai`, or Flutter's `Riverpod`.)

*   **`CoralController` (Wellspring, Root)**: The starting point of data. When a change occurs, it sends a wave (Signal) downstream.
*   **`CoralComputation` (Derived Node)**: A pure function node that transforms/derives data in the middle via `cascade`, `diverge`, etc.
*   **`Trunk` / `converge` (Bundle Node)**: Serves to bundle multiple branches of data into one.
*   **`CoralCoupler` (Dynamic Router)**: A node that allows you to disconnect a part of the pipeline or newly connect it (Hot/Cold swap) at runtime.
*   **`CoralTerminal` (Endpoint, Sink)**: The entry point that finally binds to the UI (Widget) and renders data to the screen.

### 1.2 Unidirectional Data Flow and MVI (Model-View-Intent)
Data (`Model`) flows strictly **Downstream** (top-down) from the `Controller` to the `Terminal` (`View`). 
Conversely, context changes in the UI layer or user requirements are passed **Upstream** (bottom-up) under the name of **Intent**. (Using `CorallineTerminalIntentAware`)

> [!NOTE]
> **Intent Firewall (Structural Intent Firewall)**
> A chronic problem often occurring in MVI architectures is the contradiction where multiple Views share a single Model (1:N), and each View sends up a different Intent, causing a collision. Coralline Flutter's `CoralBroadcaster` does not forcibly filter and 'block' this at runtime. By design, at the divergence point where a 1:N topology is formed, downstream Intents are topologically severed from passing upstream. It provides a **beautiful topology structure designed so that contradictory Intent collisions fundamentally cannot occur**.

---

## 2. Core Engine: Push-Dirty, Pull-Data (Lazy Computation)

Legacy `Stream`, `RxDart`, and `ValueNotifier` based architectures use a **Synchronous Push model** that pushes data through transformations (Map/Filter) down to the View unconditionally whenever data changes. When tens to hundreds of updates occur per second, this triggers a so-called **Synchronous Flood**, causing UI frame drops and severe battery drain.

Coralline Flutter adopted a **Lazy-Computation** model that completely flips this.

### Phase 1: Push-Dirty (Lightweight Signal Propagation)
When data changes, instead of passing heavy data payloads to downstream nodes, it simply plants an O(1) flag (Boolean) saying **"The cached data you hold is now obsolete (Dirty)."** No matter how many times this process occurs, the computational cost is close to zero.

### Phase 2: Automatic Debouncing (Coalescing)
Even if 1,000 data changes arrive before the UI renders the screen, the 999 signals following the first Dirty signal are ignored (absorbed).

### Phase 3: Pull-Data (UI-Driven Data Pulling)
Only when the `CoralTerminal` (UI) is ready to draw the screen in sync with the device's refresh rate (e.g., 60Hz), does it **traverse backward up the pipeline**, pull the latest data, and perform the heavy computation (Formatting, etc.) exactly once.

> [!TIP]
> **Garbage Collector (GC) Optimization**
> Generating and discarding short-lived `CoralSnapshot` instances adheres to the allocation model of the Dart VM's nursery (bump-pointer allocation) and scavenger GC, avoiding cache lookup penalties and reducing long-lived heap retention compared to global mutable state tables.

---

## 3. Direct Comparison with Other Frameworks (Including Riverpod, Signals)

| Feature Comparison | Coralline Flutter | MVVM (Legacy) | BLoC | Riverpod | Signals (Preact) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **State Storage** | **Topology-based DAG (Combination of small Nodes)** | Massive single ViewModel object | State transition-based State object | Provider graph (DAG) | Topologically sorted reactive primitives |
| **Data Propagation** | **Push-Dirty, Pull-Data (Lazy Computation)** | Two-way binding / Push | Stream Push | Push/Pull mixed (Primarily Push) | Push-Dirty, Pull-Data |
| **UI Action Handling**| **Explicit Upstream Intent (`Terminal` -> `Computation`)** | Direct ViewModel method calls | Push Event into Sink | Direct Notifier method calls | Direct Signal value mutation |
| **GC / Memory Strategy**| **Bump-pointer & Scavenger GC targeting optimization** | Regular object heap allocation | State/Event object heap allocation | Cache invalidation (`invalidate`) support | Lightweight nodes & minimized garbage |
| **Safety / Topology** | **Intent Firewall, Structural Anomaly handling (`fallback`)** | Relies on runtime error checks | Error handling during event processing | Error catch via AsyncValue | Exception propagation to derived nodes |
| **Dynamic Swap (Hotswap)**| **Framework-level zero-downtime swap (`CoralCoupler` support)** | Manual cache invalidation & reconnect | StreamSubscription cancel/reset | `ref.watch` dynamic dependency refresh | Dynamic tracking refresh within `effect` |

> [!NOTE]
> **Detailed Comparison with BLoC, Riverpod, and Signals**
>
> - **vs BLoC (Unidirectional MVI Framework)**
>   - **Shared Concepts**: Unidirectional data flow and MVI paradigm of receiving an Event/Intent to produce a State.
>   - **Design Differences**: BLoC executes state transformations synchronously upon event dispatch (Push model). Coralline Flutter separates fine-grained state into a Directed Acyclic Graph (DAG) and defers derived widget computation until the Flutter build/render phase (Pull model).
>
> - **vs Riverpod (DAG State Management)**
>   - **Shared Concepts**: Uses a Directed Acyclic Graph (DAG) to compose multiple state nodes and maintain dependency relationships.
>   - **Design Differences**: Upstream mutations in Riverpod invalidate and push re-evaluations downstream. Coralline Flutter emits an $O(1)$ push-dirty notification flag to dependent elements, deferring node computation until the active terminal pulls the value on frame rendering.
>
> - **vs Signals (Preact Reactive Primitives)**
>   - **Shared Concepts**: Shares the Push-Dirty, Pull-Data invalidation model, notifying dependents of dirty state while evaluating data on read.
>   - **Design Differences**: Signals packages focus on fine-grained reactive primitives. Coralline Flutter integrates with Flutter's element lifecycle via `CorallineBuildContextAware`, provides upstream intent routing with structural isolation via `CoralBroadcaster`, and supports runtime pipeline reconnection via `CoralCoupler`.

---

## 4. Conclusion

Coralline Flutter is structured as a **Lazy-Computed Topological Reactive DAG based on MVI principles**.

By decomposing monolithic view-model state into fine-grained reactive nodes and coordinating invalidation with Flutter's frame build cycle, Coralline Flutter prevents redundant intermediate derivations and isolates UI rebuild boundaries for predictable performance.
