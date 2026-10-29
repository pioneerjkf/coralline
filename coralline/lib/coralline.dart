// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// The foundational reactive state management framework for pure Dart and Flutter.
///
/// Coralline implements the **CORAL** (**C**hain **o**f **R**eactivity **A**nd **L**azy-computation)
/// architecture, separating change invalidation from data computation through an efficient
/// Push-Dirty, Pull-Data execution pipeline.
///
/// ## System Architectural Flow
/// ```text
/// State Mutation (Source)
///        │
///        ▼
/// [CoralController] ──> Push Dirty Signal (Mark Dirty) ──> [CoralNode Graph]
///                                                                 │
/// External Consumer <── Pull Data (Lazy Synchronous Value) <──────┘
/// ```
///
/// ## Core Subsystems
/// - **Reactive Units**: [Coral] (atomic/single-value reactive signal) and [Trunk] (composite multi-line bundle).
/// - **Imperative Sources**: [CoralController] and [TrunkController] for injecting state changes into the graph.
/// - **Distribution & Swapping**: [CoralBroadcaster] for 1:N multi-subscriber fan-out, and [CoralCoupler] and [TrunkCoupler] for runtime node swapping.
/// - **Terminal Endpoints**: [CoralTerminal] and [TrunkTerminal] for connecting external consumers and managing lifecycle.
/// - **State Encapsulation**: [CoralSnapshot], [TrunkSnapshot], and [CorallineSnapshot] for fail-fast, null-safe payload boxing.
/// - **Element Collections**: [CoralIterableElements], [CoralKeyedIterableElements], [CoralListElements], [CoralSetElements], and [CoralMapElements].
/// - **Async Adapters**: [FutureCoralExtension], [FutureCollectionTrunkExtension], [StreamCoralExtension], [StreamControllerCoralExtension], and [StreamCollectionTrunkExtension].
library;

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

part 'src/async.dart';
part 'src/broadcaster.dart';
part 'src/computation.dart';
part 'src/controller.dart';
part 'src/coral.dart';
part 'src/coupler.dart';
part 'src/debug.dart';
part 'src/elements.dart';
part 'src/exception.dart';
part 'src/lifecycle.dart';
part 'src/node.dart';
part 'src/snapshot.dart';
part 'src/terminal.dart';
part 'src/trunk.dart';

part 'src/_internal/_async.dart';
part 'src/_internal/_broadcaster.dart';
part 'src/_internal/_cascading.dart';
part 'src/_internal/_computation.dart';
part 'src/_internal/_controller.dart';
part 'src/_internal/_coral.dart';
part 'src/_internal/_coralline.dart';
part 'src/_internal/_coupler.dart';
part 'src/_internal/_debug.dart';
part 'src/_internal/_elements.dart';
part 'src/_internal/_error.dart';
part 'src/_internal/_fasttrack.dart';
part 'src/_internal/_joint.dart';
part 'src/_internal/_lifecycle.dart';
part 'src/_internal/_point.dart';
part 'src/_internal/_scheduler.dart';
part 'src/_internal/_terminal.dart';
part 'src/_internal/_topology.dart';
part 'src/_internal/_trunk.dart';
part 'src/_internal/_trunkline.dart';
part 'src/_internal/_utility.dart';
