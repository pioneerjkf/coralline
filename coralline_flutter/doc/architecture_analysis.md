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
> **Extreme Garbage Collector (GC) Optimization**
> It takes the approach of generating and discarding an infinite number of short-lived `CoralSnapshot` objects (Allocate & Discard). This perfectly matches the behavior of the V8/Dart engine's Nursery (Bump-pointer allocation) and Scavenger GC, enabling overwhelmingly faster performance and zero-overhead memory management compared to hash map caching.

---

## 3. Direct Comparison with Other Frameworks (Including Riverpod, Signals)

| Feature Comparison | Coralline Flutter | MVVM (Legacy) | BLoC | Riverpod | Signals (Preact) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **State Storage** | **Topology-based DAG (Combination of small Nodes)** | Massive single ViewModel object | State transition-based State object | Provider graph (DAG) | Topologically sorted reactive primitives |
| **Data Propagation** | **Push-Dirty, Pull-Data (Lazy Computation)** | Two-way binding / Push | Stream Push | Push/Pull mixed (Primarily Push) | Push-Dirty, Pull-Data |
| **UI Action Handling**| **Explicit Upstream Intent (`Terminal` -> `Computation`)** | Direct ViewModel method calls | Push Event into Sink | Direct Notifier method calls | Direct Signal value mutation |
| **GC / Memory Strategy**| **Bump-pointer & Scavenger GC targeting optimization** | Regular object heap allocation | State/Event object heap allocation | Cache invalidation (`invalidate`) support | Lightweight nodes & minimized garbage |
| **Safety / Topology** | **Intent Firewall, Forced structural Anomaly handling (`catchDamaged`)** | Relies on runtime error checks | Error handling during event processing | Error catch via AsyncValue | Exception propagation to derived nodes |
| **Dynamic Swap(Hotswap)**| **Framework-level zero-downtime swap (`MooringPoint` support)** | Manual cache invalidation & reconnect | StreamSubscription cancel/reset | `ref.watch` dynamic dependency refresh | Dynamic tracking refresh within `effect` |

> [!NOTE]
> **Detailed Comparison with BLoC, Riverpod, and Signals**
>
> ?뵻 **vs BLoC (Unidirectional MVI Framework)**
> - **Inherited Philosophy**: **Unidirectional data flow** and MVI concept of receiving an Event/Intent to produce a State.
> - **Legacy Limitation**: State transitions as a massive 'object chunk', and computations execute synchronously immediately upon event occurrence (Push).
> - **Coralline Flutter's Edge**: Breaks down massive state into **small topological nodes (DAG)** and optimizes by **delaying heavy computations until UI rendering (Pull)**, even under a bombardment of frequent events.
>
> ?뵻 **vs Riverpod (DAG State Management)**
> - **Inherited Philosophy**: **Directed Acyclic Graph (DAG)** topology to combine multiple states and manage dependencies.
> - **Legacy Limitation**: When data changes, the ripple effect of computations tends to propagate downstream based on microtasks or synchronous Push.
> - **Coralline Flutter's Edge**: Instead of propagating computations, it emits an O(1) **lightweight Dirty signal**, fundamentally blocking CPU waste during frequent updates.
>
> ?뵻 **vs Signals (Preact Reactive Primitives)**
> - **Inherited Philosophy**: Completely identical **Push-Dirty, Pull-Data** structure that only passes change signals and computes on read.
> - **Legacy Limitation**: Limited in controlling large-scale UI architectures as it only provides general 'Reactive Primitives'.
> - **Coralline Flutter's Edge**: Beyond simple variable management, it establishes a 'massive pipeline framework' structure tailored for the Flutter lifecycle, featuring **Upstream Intent backward propagation (MVI)**, an **Intent Firewall** to prevent 1:N topology collisions, and runtime **Hotswap (`CoralCoupler`)**.

---

## 4. Conclusion

The most accurate architectural model name to describe Coralline Flutter is the **"Lazy-Computed Topological Reactive DAG based on MVI"**.

This goes beyond simply asking "How should we manage state?", and is an architecture infused with deep contemplation on **"How do we systematically overcome the limitations of the Garbage Collector's behavior and the UI rendering pipeline?"** In particular, in UI environments accompanied by high-frequency real-time communications (stock order books, IoT monitoring, etc.) or heavy computations, it can be analyzed as a model providing incomparable, overwhelming performance and stability over other frameworks.
