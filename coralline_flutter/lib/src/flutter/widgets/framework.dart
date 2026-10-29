// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../widgets.dart';

/// A high-performance declarative UI component optimized for a single inbound dependency (1:1).
///
/// Unlike [BuildComponent] (which manages an N:1 list of inbound dependencies),
/// [SimplexBuildComponent] binds directly to a single upstream [CoralNode] returned by [manifest].
/// It computes the UI subtree lazily when marked dirty by its reactive dependency.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │         SimplexBuildComponent (1:1 Binding Flow)       │
/// └────────────────────────────────────────────────────────┘
///        │
/// [Upstream CoralNode] ──> Push-Dirty Signal ──> [SimplexBuildComponent]
///                                                       │
///                                                       └── Lazy Pull on Next Frame ──> [Widget Output]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero-Allocation Manifest**: Directly exposes a single upstream node reference without
///    allocating intermediate iterable or list wrappers.
/// 2. **Pull-Data Frame Alignment**: Evaluates [build] lazily during Flutter's layout and paint
///    cycle only when an upstream dirty signal has been dispatched.
/// 3. **Non-Virtual Compute Guard**: Symmetrical to Flutter's [StatelessWidget.build]. The internal
///    [compute] method is marked `@nonVirtual` and routes directly to [build].
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT instantiate reactive state controllers or nodes inside [build], as per-frame
///   re-instantiation resets state on every rebuild pass.
/// - Do NOT read undeclared reactive state nodes inside [build] without declaring them in [manifest].
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Instantiating a new controller inside manifest() creates an isolated source
/// base class BadCounterBadge extends SimplexBuildComponent {
///   @override
///   @manifestSync
///   CoralNode manifest() => CoralController<int>(0).coral;
///
///   @override
///   Widget build() => const Text('Disconnected from external state');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Declare stable upstream dependencies via constructor fields
/// base class GoodCounterBadge extends SimplexBuildComponent {
///   GoodCounterBadge({required this.count});
///
///   final Coral<int> count;
///
///   @override
///   @manifestSync
///   CoralNode manifest() => count;
///
///   @override
///   Widget build() => Text('Count: ${count.data}');
/// }
/// ```
///
/// ## Examples
/// ```dart
/// base class CounterBadge extends SimplexBuildComponent {
///   CounterBadge({required this.count});
///
///   final Coral<int> count;
///
///   @override
///   @manifestSync
///   CoralNode manifest() => count;
///
///   @override
///   Widget build() {
///     return Text('Count: ${count.data}');
///   }
/// }
/// ```
abstract base class SimplexBuildComponent extends SimplexComputation<Widget> {
  @override
  @nonVirtual
  @pragma('vm:prefer-inline')
  Widget compute() => build();

  /// Declares the single upstream reactive dependency [CoralNode] that powers this component.
  ///
  /// This method is called during node instantiation to bind the 1:1 topological link.
  ///
  /// **Requires:**
  /// * Must return the exact single [CoralNode] or [Coral] stream accessed inside [build].
  /// * Must be annotated with `@manifestSync`.
  ///
  /// **Ensures:**
  /// * Declares the upstream node observed by this component.
  ///
  /// **Implementation note:**
  /// Always return the exact single reactive dependency used in [build]. Returning a different node
  /// or instantiating new nodes inside [manifest] will cause topological binding errors or lost updates.
  @override
  @manifestSync
  CoralNode manifest();

  /// Builds the declarative UI [Widget] subtree based on the single reactive state.
  ///
  /// Symmetrical to Flutter's [StatelessWidget.build].
  ///
  /// **Ensures:**
  /// * Returns a non-null declarative UI [Widget] subtree.
  Widget build();
}

/// A base component for assembling declarative UI [Widget] subtrees from multiple reactive dependencies (N:1).
///
/// [BuildComponent] bridges Coralline's reactive state computation with Flutter's
/// declarative layout system by exposing a Flutter-friendly [build] method. It computes
/// the UI subtree lazily when marked dirty by any of its declared reactive dependencies.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │           BuildComponent (N:1 Topological Flow)        │
/// └────────────────────────────────────────────────────────┘
/// [CoralNode A] ──┐
/// [CoralNode B] ──┼──> Push-Dirty Signal ──> [BuildComponent]
/// [CoralNode C] ──┘                                 │
///                                                   └── Lazy Pull on Next Frame ──> [Widget Output]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Coalesced Multi-Dependency Invalidation**: Multiple simultaneous upstream invalidations
///    within a single frame coalesce into a single lazy [build] invocation.
/// 2. **Topological Purity**: Decouples UI assembly from Flutter's widget lifecycle while
///    maintaining full reactivity across dynamic state changes.
/// 3. **Non-Virtual Compute Guard**: Symmetrical to Flutter's [StatelessWidget.build]. The internal
///    [compute] method is marked `@nonVirtual` and routes directly to [build].
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT access undeclared [CoralNode]s inside [build] without declaring them in [manifest].
///   Undeclared dependencies bypass the topological graph and fail to trigger automatic UI updates.
/// - Do NOT store mutable UI state in local instance fields. Always derive state declaratively from [Coral].
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Accessing undeclared reactive state inside build misses updates
/// base class BadProfileCard extends BuildComponent {
///   BadProfileCard(this.nameCoral, this.ageCoral);
///   final Coral<String> nameCoral;
///   final Coral<int> ageCoral;
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [nameCoral]; // Missing ageCoral!
///
///   @override
///   Widget build() => Text('${nameCoral.data}: ${ageCoral.data}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Exhaustively declare all accessed nodes in manifest
/// base class GoodProfileCard extends BuildComponent {
///   GoodProfileCard(this.nameCoral, this.ageCoral);
///   final Coral<String> nameCoral;
///   final Coral<int> ageCoral;
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [nameCoral, ageCoral];
///
///   @override
///   Widget build() => Text('${nameCoral.data}: ${ageCoral.data}');
/// }
/// ```
///
/// ## Examples
/// ```dart
/// base class CounterViewComp extends BuildComponent {
///   CounterViewComp({required this.count});
///
///   final Coral<int> count;
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [count];
///
///   @override
///   Widget build() {
///     return Text('Count: ${count.data}');
///   }
/// }
/// ```
abstract base class BuildComponent extends ComplexComputation<Widget> {
  @override
  @nonVirtual
  @pragma('vm:prefer-inline')
  Widget compute() => build();

  /// Declares all upstream reactive dependency [CoralNode]s that power this component.
  ///
  /// This method is called during node instantiation to bind the N:1 topological graph links.
  ///
  /// **Requires:**
  /// * Must return an iterable of all [CoralNode]s or [Coral] streams accessed inside [build].
  /// * Must be annotated with `@manifestSync`.
  ///
  /// **Ensures:**
  /// * Establishes topological reactive links to all declared upstream nodes, ensuring
  ///   this component is re-computed lazily whenever any declared node emits dirty signals.
  ///
  /// **Implementation note:**
  /// Every [Coral] or [CoralNode] accessed within [build] MUST be included in the returned iterable.
  /// Accessing an undeclared [CoralNode] inside [build] violates topological security and will fail
  /// to trigger automatic UI updates when that dependency changes.
  @override
  @manifestSync
  Iterable<CoralNode> manifest();

  /// Builds the declarative UI [Widget] subtree based on the reactive state.
  ///
  /// Symmetrical to Flutter's [StatelessWidget.build].
  ///
  /// **Ensures:**
  /// * Returns a non-null declarative UI [Widget] subtree.
  Widget build();
}

/// A Flutter widget that binds a [Coral] of [Widget]s to the element tree.
///
/// [CoralWidget] acts as the terminal boundary that listens to the reactive pipeline
/// and rebuilds itself whenever the underlying [coral] emits a new [Widget].
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │              CoralWidget Terminal Boundary             │
/// └────────────────────────────────────────────────────────┘
/// [Reactive Pipeline] ──> Push-Dirty ──> [CoralWidgetElement]
///                                              │
///                                              └── Evaluates & Renders on Frame ──> [Flutter Element]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Lazy Frame-Aligned Pull**: Performs lazy pull computations of the UI tree only
///    when marked dirty and requested by Flutter's frame scheduler.
/// 2. **Integrated Error Isolation**: Supports [errorBuilder] to gracefully intercept
///    damaged pipeline states without crashing the host application.
/// 3. **Dynamic Coupler Integration**: Embeds an internal [CoralCoupler] to support
///    hotswapping pipelines without tearing down the underlying element tree.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT pass new un-memoized [coral] references on every parent build pass,
///   as doing so triggers unnecessary pipeline hotswapping.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Creating a new Coral instance inside build forces continuous hotswaps
/// Widget build(BuildContext context) {
///   return CoralWidget(
///     coral: CoralController<Widget>(Text('Hello')).coral,
///   );
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Bind to an existing, stably referenced Coral pipeline
/// class StoredWidgetView extends StatelessWidget {
///   const StoredWidgetView({super.key, required this.uiCoral});
///   final Coral<Widget> uiCoral;
///
///   @override
///   Widget build(BuildContext context) => CoralWidget(coral: uiCoral);
/// }
/// ```
///
/// ## Examples
/// ```dart
/// final controller = CoralController<int>(0);
/// final uiCoral = controller.provider.coral.map(
///   (count) => Text('Count: $count'),
/// );
/// final widget = CoralWidget(
///   coral: uiCoral,
///   errorBuilder: (context, error, stackTrace) => Text('Error: $error'),
/// );
/// ```
class CoralWidget extends Widget {
  /// Creates a [CoralWidget] bound to the given reactive [coral] pipeline.
  ///
  /// * [key]: Optional Flutter widget key.
  /// * [coral]: The reactive [Coral] pipeline providing the declarative UI [Widget].
  /// * [errorBuilder]: Optional fallback builder invoked when the pipeline enters a damaged state.
  const CoralWidget({
    super.key,
    required this.coral,
    this.errorBuilder,
  });

  /// The reactive [Coral] node that provides the declarative UI [Widget].
  final Coral<Widget> coral;

  /// An optional builder function rendering a fallback UI if the pipeline enters a damaged state.
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  @override
  CoralWidgetElement createElement() => CoralWidgetElement(this);
}

/// The element managing the lifecycle of the reactive [CoralTerminal] for a [CoralWidget].
///
/// [CoralWidgetElement] acts as the bridge between Flutter's element tree and Coralline's
/// topological pipeline, converting dirty signals into framework rebuilds.
///
/// Maintains a [CoralTerminal] to drive the reactive pipeline. When inherited dependencies
/// change (via [ComponentElement.didChangeDependencies]), it suppresses the immediate default
/// Flutter rebuild and forwards the updated [BuildContext] into `_intent._contextController`.
/// A rebuild is then scheduled via [markNeedsBuild] only if a declared upstream or context-derived
/// dependency (such as [CorallineBuildContextAware.dependOn]) marks the terminal dirty.
///
/// **Implementation note:**
/// - Never call `markNeedsBuild` directly unless you bypass the terminal's dirty propagation.
/// - Ensure [unmount] cleanly deactivates the terminal to prevent subscription/memory leaks.
base class CoralWidgetElement extends ComponentElement {
  /// Creates a [CoralWidgetElement] for the given [widget].
  CoralWidgetElement(CoralWidget super.widget);

  late final _intent = CoralWidgetTerminalIntent(context: this);

  late final _terminal = CoralTerminal<Widget>.withIntent(
    _coupler.coral.fallback(onEmpty: _handleEmpty, onDamage: _handleDamage),
    intent: _intent,
    onDirty: markNeedsBuild,
  );

  late final CoralCoupler<Widget> _coupler =
      CoralCoupler<Widget>.late(seal: false, hotswap: true);

  /// Tracks inherited element dependencies for fine-grained flushing during pipeline hot-swapping.
  final Set<InheritedElement> _trackedDependencies = {};

  bool _isFirstBuild = true;

  /// A flag to suppress the default rebuild triggered by the framework during dependency updates.
  bool _suppressMarkNeedsBuild = false;

  Widget _handleEmpty() => const Offstage();

  Widget _handleDamage(Object error, [StackTrace? stackTrace]) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: _libraryName,
    ));

    final errorBuilder = (widget as CoralWidget).errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(this, error, stackTrace);
    }
    return const Offstage();
  }

  /// Clears tracked inherited element dependencies to prevent ghost notifications after pipeline changes.
  void _flushDependencies() {
    if (_trackedDependencies.isEmpty) return;

    for (final ancestor in _trackedDependencies) {
      // ignore: invalid_use_of_protected_member
      ancestor.removeDependent(this);
    }
    _trackedDependencies.clear();
  }

  /// Updates the element with a new widget configuration.
  ///
  /// This couples the internal [CoralCoupler] to the new widget's [Coral] pipeline.
  ///
  /// * [newWidget]: The new widget configuration.
  ///
  /// **Ensures:**
  /// * The internal coupler is bound to the new widget's coral.
  /// * If the element is marked dirty, a rebuild is scheduled.
  @override
  void update(covariant CoralWidget newWidget) {
    try {
      if (_coupler.couple(newWidget.coral) != null) {
        _flushDependencies();
      }
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }

    super.update(newWidget);

    if (dirty) {
      rebuild();
    }
  }

  @mustCallSuper
  @override
  void performRebuild() {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _terminal.activate();
      _coupler.couple((widget as CoralWidget).coral);
    }
    super.performRebuild();
  }

  @override
  Widget build() {
    return _terminal.data;
  }

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor,
      {Object? aspect}) {
    final result = super.dependOnInheritedElement(ancestor, aspect: aspect);
    _trackedDependencies.add(ancestor);
    return result;
  }

  /// Intercepts framework dependency updates to push the updated [BuildContext] into the reactive pipeline.
  ///
  /// **Requires:**
  /// * Must be called by Flutter's element lifecycle during dependency changes.
  ///
  /// **Ensures:**
  /// * Suppresses immediate framework rebuilds and delegates context updates to `_intent._contextController`.
  /// * Schedules a rebuild via [markNeedsBuild] only if a context-derived dependency marks the terminal dirty.
  @mustCallSuper
  @override
  void didChangeDependencies() {
    _suppressMarkNeedsBuild = true;
    try {
      super.didChangeDependencies();
    } finally {
      _suppressMarkNeedsBuild = false;
      // Instead of forcing an unconditional rebuild, forward the context update to the reactive pipeline.
      // The terminal triggers markNeedsBuild only when a context-derived node propagates a dirty signal.
      _intent._contextController.set(this);
    }
  }

  @override
  void markNeedsBuild() {
    if (_suppressMarkNeedsBuild) return;
    super.markNeedsBuild();
  }

  /// Cleans up the reactive pipeline when the element is removed from the tree.
  ///
  /// **Ensures:**
  /// * The underlying [CoralTerminal] is deactivated.
  /// * The [CoralCoupler] is decoupled, freeing any topological references.
  @override
  void unmount() {
    try {
      _trackedDependencies.clear();
      _terminal.deactivate();
      _coupler.decouple();
      _intent._contextController.empty();
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }

    super.unmount();
  }
}

/// An intent specifically designed to carry Flutter's [BuildContext] into the Coralline
/// reactive pipeline.
///
/// Topologically routes the active [BuildContext] from a [CoralWidgetElement] into
/// a [CorallineBuildContextAware] computation, enabling business logic to access dynamic
/// UI environment context without storing mutable element references.
base class CoralWidgetTerminalIntent extends CorallineTerminalIntent {
  /// The element context bound to this intent.
  final BuildContext _context;

  /// Creates a new intent carrying the given element [BuildContext].
  CoralWidgetTerminalIntent({required BuildContext context})
      : _context = context;

  /// The internal controller emitting active element [BuildContext] updates.
  ///
  /// Using a non-distinct controller ensures element dependency updates notify
  /// downstream context-aware computations even when the [BuildContext] instance identity is unchanged.
  late final _contextController =
      CoralController<BuildContext>(_context, broadcast: true, distinct: false);

  /// The reactive provider that streams the latest [BuildContext].
  ///
  /// **Constraints:**
  /// This must stream valid, active [BuildContext] objects and update them whenever
  /// [CoralWidgetElement.didChangeDependencies] is triggered.
  late final CoralProvider<BuildContext> contextProvider =
      _contextController.provider;
}

/// A mixin enabling a [CoralComputation] to receive [BuildContext] updates from a [CoralWidget].
///
/// Computations reside outside the widget tree and cannot directly invoke Flutter's
/// imperative element lookup APIs during execution. [CorallineBuildContextAware] bridges
/// this boundary by routing the active [BuildContext] as a reactive [context] stream.
///
/// ## System Architectural Flow
/// ```text
/// ┌─────────────────────────────────────────────────────────────────┐
/// │               CorallineBuildContextAware Flow                   │
/// └─────────────────────────────────────────────────────────────────┘
/// [CoralWidgetElement] ──> Passes Intent ──> [CoralWidgetTerminalIntent]
///                                                    │
///                                                    └── Couples contextProvider ──> [CorallineBuildContextAware.context]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Intent-Driven Decoupling**: Business logic derives UI dependencies (Theme, MediaQuery)
///    without storing mutable [BuildContext] references.
/// 2. **Broadcaster Line Caching**: Accessing [context] exposes a broadcaster stream. Derived
///    child nodes must be cached in `late final` fields to maintain stable topological links.
/// 3. **Automatic Dependency Clean-Up**: Transitioning or decoupling contexts automatically
///    unregisters tracked inherited element listeners, preventing memory and listener leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT access [context] repeatedly inside `build()` or `compute()` without caching in a `late final` field.
///   Each un-cached read creates a separate unattached broadcaster line that fails with a dormant access error.
/// - Do NOT store the emitted [BuildContext] in a local mutable field.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Uncached context reads inside build create unattached dormant lines
/// base class BadThemedComponent extends BuildComponent
///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() {
///     final dir = context.map((ctx) => Directionality.of(ctx)).data; // Fails!
///     return Text('Direction: $dir');
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Cache derived context nodes in late final fields and declare in manifest
/// base class GoodThemedComponent extends BuildComponent
///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
///   late final dirCoral = context.map((ctx) => Directionality.of(ctx)).distinct();
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [dirCoral];
///
///   @override
///   Widget build() => Text('Direction: ${dirCoral.data}');
/// }
/// ```
///
/// ## Examples
/// ```dart
/// base class ThemedStatusCard extends BuildComponent
///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
///   ThemedStatusCard({required this.messageCoral});
///   final Coral<String> messageCoral;
///
///   late final dirCoral = context.map((ctx) => Directionality.of(ctx)).distinct();
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [messageCoral, dirCoral];
///
///   @override
///   Widget build() {
///     return Directionality(
///       textDirection: dirCoral.data,
///       child: Text(messageCoral.data),
///     );
///   }
/// }
/// ```
base mixin CorallineBuildContextAware on CorallineTerminalIntentAware {
  final _contextCoupler = CoralCoupler<BuildContext>.late();

  late final _contextProvider = _contextCoupler.toBroadcaster();

  /// The reactive [Coral] node that exposes the current [BuildContext] stream.
  ///
  /// Used to derive child [Coral] nodes that react to UI context changes such
  /// as theme, localization, or media query updates.
  ///
  /// **Constraints & Behavior:**
  /// Every access to [context] invokes `_contextProvider.coral`, creating a
  /// **new distinct broadcaster line node instance**.
  ///
  /// **Implementation note (Broadcaster Line Warning):**
  /// - Reading [context] repeatedly or inside `compute()` without caching
  ///   creates separate unattached or dormant line instances.
  /// - Pulling data from an unattached line node will fail with a state error
  ///   ([CoralBroadcasterLineDormantAccessError]).
  /// - **Best Practice:** Always cache derived nodes in `late final` fields or
  ///   store the [context] instance before registering it in [ComplexComputation.manifest].
  @protected
  Coral<BuildContext> get context => _contextProvider.coral;

  /// Intercepts incoming terminal intents to extract and couple the [BuildContext] provider.
  ///
  /// * [oldIntent]: The previously active intent, if any.
  /// * [newIntent]: The new intent being applied to the terminal.
  ///
  /// **Ensures:**
  /// * If [newIntent] is a [CoralWidgetTerminalIntent], its provider's coral is coupled.
  /// * Otherwise, the internal context coupler is decoupled.
  @mustCallSuper
  @override
  void didUpdateIntent({
    CorallineTerminalIntent? oldIntent,
    CorallineTerminalIntent? newIntent,
  }) {
    try {
      super.didUpdateIntent(oldIntent: oldIntent, newIntent: newIntent);
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }

    final finalOldIntent =
        oldIntent is CoralWidgetTerminalIntent ? oldIntent : null;
    final finalNewIntent =
        newIntent is CoralWidgetTerminalIntent ? newIntent : null;

    if (finalNewIntent != null) {
      _contextCoupler.couple(finalNewIntent.contextProvider.coral);
    } else {
      _contextCoupler.decouple();
    }

    if (!identical(finalOldIntent?._context, finalNewIntent?._context)) {
      didUpdateBuildContext(finalOldIntent?._context, finalNewIntent?._context);
    }
  }

  /// Intercepts element tree lifecycle changes when the bound [BuildContext] transitions.
  ///
  /// This hook triggers ONLY when the underlying element instance changes (e.g., initial
  /// coupling, widget subtree reparenting, or decoupling).
  ///
  /// * [oldContext]: The previously bound [BuildContext], or `null` if unmounted or uncoupled.
  /// * [newContext]: The newly bound active [BuildContext], or `null` if decoupled.
  ///
  /// **Ensures:**
  /// * Invoked only when `!identical(oldContext, newContext)` at the element reference level.
  void didUpdateBuildContext(
      BuildContext? oldContext, BuildContext? newContext) {}

  /// Creates a reactive [Coral] pipeline subscribing to an [InheritedWidget] of type [T] from the element tree.
  ///
  /// * [aspect]: Optional aspect identifier for fine-grained dependency tracking when [T] is an [InheritedModel].
  ///
  /// **Requires:**
  /// * An ancestor [InheritedWidget] of type [T] must exist in the element tree when evaluated.
  ///
  /// **Ensures:**
  /// * Automatically re-computes the pipeline whenever [T] (or [aspect]) updates.
  /// * Returns a non-null reactive [Coral<T>] pipeline emitting instances of [T].
  /// * If no ancestor [InheritedWidget] of type [T] is found when the returned [Coral] is evaluated,
  ///   a [TypeError] is thrown inside the mapping step and captured as a `damaged` snapshot state
  ///   (which throws a [CoralSnapshotExtractionException] when `.data` is read). Use [maybeDependOn] if the ancestor is optional.
  ///
  /// ## Examples
  /// ```dart
  /// base class ThemedComponent extends BuildComponent
  ///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
  ///   late final directionalityCoral = dependOn<Directionality>();
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [directionalityCoral];
  ///
  ///   @override
  ///   Widget build() => Text('Dir: ${directionalityCoral.data.textDirection}');
  /// }
  /// ```
  @protected
  @pragma('vm:prefer-inline')
  Coral<T> dependOn<T extends InheritedWidget>({Object? aspect}) {
    return context
        .map((e) => e.dependOnInheritedWidgetOfExactType<T>(aspect: aspect)!)
        .distinct();
  }

  /// Creates a null-safe reactive [Coral] pipeline subscribing to an optional [InheritedWidget] of type [T].
  ///
  /// * [aspect]: Optional aspect identifier for fine-grained dependency tracking when [T] is an [InheritedModel].
  ///
  /// **Ensures:**
  /// * Returns a reactive [Coral<T?>] pipeline emitting [T] or `null` if [T] is absent from the tree.
  ///
  /// ## Examples
  /// ```dart
  /// base class CustomScopeComponent extends BuildComponent
  ///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
  ///   late final optionalThemeCoral = maybeDependOn<DefaultTextStyle>();
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [optionalThemeCoral];
  ///
  ///   @override
  ///   Widget build() => Text('Style: ${optionalThemeCoral.data?.style}');
  /// }
  /// ```
  @protected
  @pragma('vm:prefer-inline')
  Coral<T?> maybeDependOn<T extends InheritedWidget>({Object? aspect}) {
    return context
        .map((e) => e.dependOnInheritedWidgetOfExactType<T>(aspect: aspect))
        .distinct();
  }

  /// Reactively subscribes to an ancestor [InheritedCoralProviderWidget] and unwraps its inner [Coral<T>] state.
  ///
  /// Locates the nearest [InheritedCoralProviderWidget] providing type [T] in the ancestor tree
  /// and flattens its underlying pipeline into a unified reactive stream.
  ///
  /// ## Key Invariants & Architectural Benefits
  /// 1. **Context Decoupling**: Accesses ancestor state within business class fields without storing `BuildContext`.
  /// 2. **Cascade Stream Flattening**: Internally evaluates as:
  ///    `dependOn<InheritedCoralProviderWidget<T>>().cascade((data) => data.provider.coral)`
  ///    Flattens ancestor widget tree updates and inner state mutations into a single [Coral<T>] stream.
  /// 3. **Topological Safety**: Subscribes dynamically when declared in `manifest()`.
  ///
  /// **Requires:**
  /// * An ancestor [InheritedCoralProviderWidget] providing type [T] must exist in the element tree.
  ///
  /// **Ensures:**
  /// * Returns a non-null reactive [Coral<T>] pipeline.
  /// * If no ancestor [InheritedCoralProviderWidget] of type [T] is found when evaluated,
  ///   a [TypeError] is captured as a `damaged` snapshot state (which throws a [CoralSnapshotExtractionException]
  ///   when `.data` is read). Use [maybeCoralOf] if optional.
  ///
  /// ## Examples
  /// ```dart
  /// base class CounterConsumer extends BuildComponent
  ///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
  ///   late final counterCoral = coralOf<int>();
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [counterCoral];
  ///
  ///   @override
  ///   Widget build() => Text('Count: ${counterCoral.data}');
  /// }
  /// ```
  @protected
  @pragma('vm:prefer-inline')
  Coral<T> coralOf<T>() {
    return dependOn<InheritedCoralProviderWidget<T>>()
        .cascade((data) => data.provider.coral);
  }

  /// Reactively subscribes to an optional ancestor [InheritedCoralProviderWidget] and unwraps its inner [Coral<T?>] state.
  ///
  /// Locates the nearest [InheritedCoralProviderWidget] providing type [T] in the ancestor tree
  /// and flattens its underlying pipeline, emitting `null` if the provider is absent.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Coral<T?>] pipeline emitting [T] or `null`.
  ///
  /// ## Examples
  /// ```dart
  /// base class OptionalConsumer extends BuildComponent
  ///     with CorallineTerminalIntentAware, CorallineBuildContextAware {
  ///   late final optionalCountCoral = maybeCoralOf<int>();
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [optionalCountCoral];
  ///
  ///   @override
  ///   Widget build() => Text('Count: ${optionalCountCoral.data ?? 0}');
  /// }
  /// ```
  @protected
  @pragma('vm:prefer-inline')
  Coral<T?> maybeCoralOf<T>() {
    return maybeDependOn<InheritedCoralProviderWidget<T>>()
        .cascade((data) => data?.provider.coral ?? Coral.data(null));
  }
}

/// A component that reactively binds a [CoralProvider] pipeline to an [InheritedCoralProviderWidget].
///
/// [InheritedCoralProvider] extends [SimplexBuildComponent] to continuously monitor changes
/// in [providerCoral] and dynamically update the underlying [InheritedCoralProviderWidget]
/// in Flutter's widget tree.
///
/// ## System Architectural Flow
/// ```text
/// [providerCoral] ──> Push-Dirty ──> [InheritedCoralProvider]
///                                           │
///                                           └── Builds ──> [InheritedCoralProviderWidget<T>]
/// ```
///
/// ## Examples
/// ```dart
/// final controller = CoralController<int>(0);
/// final appWidget = InheritedCoralProvider<int>(
///   providerCoral: Coral.data(controller.provider),
///   child: const Text('Descendant Tree'),
/// ).toWidget();
/// ```
base class InheritedCoralProvider<T> extends SimplexBuildComponent {
  /// Creates an [InheritedCoralProvider] binding [providerCoral] to [child].
  ///
  /// * [providerCoral]: The reactive [Coral] stream emitting active [CoralProvider] instances.
  /// * [child]: The widget subtree below this provider in the element tree.
  InheritedCoralProvider({
    required this.providerCoral,
    required this.child,
  });

  /// The reactive [Coral] stream emitting active [CoralProvider] instances.
  final Coral<CoralProvider<T>> providerCoral;

  /// The widget subtree below this provider in the element tree.
  final Widget child;

  @override
  @manifestSync
  CoralNode manifest() => providerCoral;

  @override
  Widget build() => InheritedCoralProviderWidget<T>(
      provider: providerCoral.data, child: child);
}

/// An [InheritedWidget] wrapper that provides a [CoralProvider<T>] to descendant widgets in the element tree.
///
/// [InheritedCoralProviderWidget] exposes a strongly-typed [provider] (`CoralProvider<T>`)
/// down the element tree, allowing descendant [CorallineBuildContextAware] computations
/// to reactively subscribe via `coralOf<T>()` or `maybeCoralOf<T>()`.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │          InheritedCoralProviderWidget Flow             │
/// └────────────────────────────────────────────────────────┘
/// [Business State (CoralProvider<T>)]
///        │
///        ▼ (toInheritedWidget / Adapting)
/// [InheritedCoralProviderWidget<T>] (Inject into Flutter Element Tree)
///        │
///        ▼ (O(1) dependOnInheritedWidgetOfExactType + cascade flattening)
/// [coralOf<T>()] (Subscribed in downstream CorallineBuildContextAware mixin)
///        │
///        ▼ (Push-Dirty, Pull-Data)
/// [UI Rendering (CoralWidget)]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **$O(1)$ Engine-Level Lookup Performance**: Leverages Flutter engine's internal `_inheritedElements`
///    HashMap via `dependOnInheritedWidgetOfExactType` to look up ancestor providers.
/// 2. **Decoupled Layered Architecture**: Bridges pure Dart reactive logic ([CoralProvider])
///    with Flutter's element tree without coupling business logic to Flutter UI lifecycles.
/// 3. **Automatic Reactive Unwrapping**: Downstream components consume state via `coralOf<T>()`,
///    which flattens tree updates and inner [Coral] state changes into a unified stream.
/// 4. **Push-Dirty, Pull-Data Scheduling**: Aligns data propagation with Flutter's frame pipeline,
///    preventing unnecessary widget rebuilds.
///
/// **Static & Dynamic Injection Strategy (Multi vs Single-Subscriber Rules):**
/// - **Multi-Subscriber Injection (Recommended for Widget Trees):** When a provider is injected into
///   the widget tree and multiple descendant components consume `coralOf<T>()` concurrently, wrap static
///   data with `CoralBroadcaster` (or set `broadcast: true` on `CoralController`). This enables 1:N
///   multi-cast fan-out and prevents single-subscriber ownership collision errors.
/// - **Single-Subscriber Injection:** If guaranteed that only a single descendant
///   component consumes the state reactively via `coralOf<T>()`, you can wrap the raw static object directly using `CoralProvider.data`.
///
/// ## Examples
/// ```dart
/// final controller = CoralController<int>(42, broadcast: true);
/// final app = InheritedCoralProviderWidget<int>(
///   provider: controller.provider,
///   child: const Text('Descendants access via coralOf<int>()'),
/// );
/// ```
class InheritedCoralProviderWidget<T> extends InheritedWidget {
  /// Creates an [InheritedCoralProviderWidget] providing [provider] to [child].
  ///
  /// * [provider]: The strongly-typed [CoralProvider] made available to descendants.
  /// * [child]: The widget subtree below this provider in the element tree.
  /// * [key]: Optional widget key.
  const InheritedCoralProviderWidget({
    required this.provider,
    required super.child,
    super.key,
  });

  /// The strongly-typed [CoralProvider] made available to descendants.
  final CoralProvider<T> provider;

  @override
  bool updateShouldNotify(covariant InheritedCoralProviderWidget<T> oldWidget) {
    return oldWidget.provider != provider;
  }
}

/// A convenience extension for converting a [CoralComputation] of [Widget]s directly into
/// a strongly-typed [CoralWidget], preserving the specific generic type `<T>`.
extension CoralComputationWidgetExtension<T extends CoralComputation<Widget>>
    on T {
  /// Converts this Computation into a strongly-typed [CoralWidget].
  ///
  /// * [key]: Optional key for the [CoralWidget].
  /// * [errorBuilder]: Optional builder to render a fallback widget if the Computation fails.
  ///
  /// **Ensures:**
  /// * Returns a new [CoralWidget] containing this Computation's [coral] pipeline.
  ///
  /// ## Examples
  /// ```dart
  /// base class CounterView extends SimplexBuildComponent {
  ///   @override
  ///   @manifestSync
  ///   CoralNode manifest() => Coral.data(0);
  ///   @override
  ///   Widget build() => const Text('Counter View');
  /// }
  /// final widget = CounterView().toWidget();
  /// ```
  CoralWidget toWidget({
    Key? key,
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace)?
        errorBuilder,
  }) {
    return CoralWidget(key: key, coral: coral, errorBuilder: errorBuilder);
  }
}

/// A convenience extension for converting a [Coral] of [Widget]s directly into a [CoralWidget].
extension CoralWidgetExtension on Coral<Widget> {
  /// Converts this [Coral] node into a [CoralWidget].
  ///
  /// * [key]: Optional key for the [CoralWidget].
  /// * [errorBuilder]: Optional builder to render a fallback widget if the pipeline is damaged.
  ///
  /// **Ensures:**
  /// * Returns a new [CoralWidget] containing this [Coral] pipeline.
  ///
  /// ## Examples
  /// ```dart
  /// final uiCoral = Coral.data<Widget>(const Text('Hello Coralline'));
  /// final widget = uiCoral.toWidget();
  /// ```
  CoralWidget toWidget({
    Key? key,
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace)?
        errorBuilder,
  }) =>
      CoralWidget(key: key, coral: this, errorBuilder: errorBuilder);
}

/// A convenience extension for converting a [CoralProvider] of [Widget]s directly into a [CoralWidget].
extension CoralWidgetProviderExtension on CoralProvider<Widget> {
  /// Converts this [CoralProvider] into a [CoralWidget].
  ///
  /// * [key]: Optional key for the [CoralWidget].
  /// * [errorBuilder]: Optional builder to render a fallback widget if the pipeline is damaged.
  ///
  /// **Ensures:**
  /// * Returns a new [CoralWidget] containing this provider's [coral] pipeline.
  ///
  /// ## Examples
  /// ```dart
  /// final controller = CoralController<Widget>(const Text('Provided Widget'));
  /// final widget = controller.provider.toWidget();
  /// ```
  CoralWidget toWidget({
    Key? key,
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace)?
        errorBuilder,
  }) =>
      CoralWidget(key: key, coral: coral, errorBuilder: errorBuilder);
}

/// A convenience extension for converting a [CoralProvider] into an [InheritedCoralProviderWidget].
extension CoralProviderInheritedWidgetExtension<T> on CoralProvider<T> {
  /// Converts this [CoralProvider] into an [InheritedCoralProviderWidget].
  ///
  /// Bridges this reactive state provider into Flutter's element tree.
  /// See [InheritedCoralProviderWidget] for complete architectural invariants,
  /// multi-subscriber injection strategies, and element lookup semantics.
  ///
  /// * [key]: Optional key for the [InheritedCoralProviderWidget].
  /// * [child]: The widget subtree below this provider in the element tree.
  ///
  /// **Ensures:**
  /// * Returns a new [InheritedCoralProviderWidget<T>] wrapping this provider and [child].
  ///
  /// ## Examples
  /// ```dart
  /// final controller = CoralController<int>(10, broadcast: true);
  /// final appWidget = controller.provider.toInheritedWidget(
  ///   child: const Text('Descendants consume via coralOf<int>()'),
  /// );
  /// ```
  InheritedCoralProviderWidget<T> toInheritedWidget(
          {Key? key, required Widget child}) =>
      InheritedCoralProviderWidget<T>(key: key, provider: this, child: child);
}
