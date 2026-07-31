// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../widgets.dart';

/// A high-performance declarative UI component optimized for a single inbound dependency (1:1).
///
/// Unlike [BuildComponent] (which manages an N:1 list of inbound dependencies),
/// [SimplexBuildComponent] binds directly to a single upstream [CoralNode] returned by [manifest].
///
/// **Design Philosophy:**
/// Eliminates list allocations (`List.unmodifiable`) and iteration overhead for single-stream
/// UI components (such as badges, toggles, or dynamic labels).
///
/// **AI & Developer Note:**
/// - Implement [build] instead of overriding [compute]. The [compute] method is marked `@nonVirtual`
///   and forwards directly to [build].
/// - Use [SimplexBuildComponent] whenever a UI component reads from exactly one [Coral] or [CoralNode].
/// - If your component requires multiple dependencies, use [BuildComponent].
///
/// **Example:**
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
  /// * Establishes a direct, zero-allocation reactive link to the declared upstream node.
  ///
  /// **AI & Developer Note:**
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
/// declarative layout system by exposing a Flutter-friendly [build] method.
///
/// **Design Philosophy:**
/// This class encapsulates the [ComplexComputation] computation contract to provide a familiar,
/// Flutter-like developer experience (`build()`). However, it remains a true reactive node within
/// Coralline's topological pipeline rather than a Flutter [Widget]. It computes the UI subtree lazily
/// when marked dirty by its reactive dependencies.
///
/// **AI & Developer Note:**
/// - Implement [build] instead of overriding [compute]. The [compute] method is marked `@nonVirtual`
///   and forwards directly to [build].
/// - Do not store dynamic UI state in local mutable fields. Always derive UI declaratively from reactive
///   [Coral] streams to maintain topological purity and prevent state synchronization bugs.
/// - Ensure all reactive dependencies accessed within [build] are declared in [manifest].
/// - For single-dependency (1:1) UI components, consider using [SimplexBuildComponent] for zero-allocation performance.
///
/// **Example:**
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
  /// **AI & Developer Note:**
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
/// **Design Philosophy:**
/// Bridges Flutter's imperative widget lifecycle with the declarative, reactive topology of
/// Coralline. It wraps the reactive stream into a single [ComponentElement] ([CoralWidgetElement]),
/// performing lazy pull computations of the UI tree only when marked dirty.
///
/// **AI & Developer Note:**
/// - Do not pass dynamic or constantly changing [coral] references to the same [CoralWidget]
///   instance, as it may force unnecessary coupler hot-swapping.
/// - Use the `.toWidget()` extension methods on [Coral], [CoralProvider], or [ComplexComputation<Widget>]
///   for a more ergonomic conversion.
///
/// **Example:**
/// ```dart
/// final Coral<Widget> myUiCoral = ...;
/// final widget = CoralWidget(
///   coral: myUiCoral,
///   errorBuilder: (context, error, stackTrace) => Text('Error: $error'),
/// );
/// ```
class CoralWidget extends Widget {
  const CoralWidget({super.key, required this.coral, this.errorBuilder});

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
/// **Design Philosophy:**
/// Maintains a [CoralTerminal] to drive the reactive pipeline. When dependencies change
/// (via [didChangeDependencies]), it suppresses the standard Flutter rebuild and forwards the
/// change into the reactive [contextProvider]. Rebuild is only scheduled if the terminal's
/// final computed UI widget actually changes, avoiding redundant layout and render passes.
///
/// **AI & Developer Note:**
/// - Never call `markNeedsBuild` directly unless you bypass the terminal's dirty propagation.
/// - Ensure [unmount] cleanly deactivates the terminal to prevent subscription/memory leaks.
base class CoralWidgetElement extends ComponentElement {
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
  /// * Schedules a rebuild only if the reactive pipeline computes a modified UI subtree.
  @mustCallSuper
  @override
  void didChangeDependencies() {
    _suppressMarkNeedsBuild = true;
    try {
      super.didChangeDependencies();
    } finally {
      _suppressMarkNeedsBuild = false;
      // Instead of forcing a rebuild, delegate the context update to the reactive pipeline.
      // The terminal will trigger markNeedsBuild only if the resulting UI actually changes.
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
  /// Using a non-distinct stream ensures element updates trigger computation
  /// computations from reacting to dynamic UI dependency changes.
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
/// Business logic (Computations) often needs to resolve dependencies (like Theme, MediaQuery, or
/// InheritedWidgets) requiring a [BuildContext]. Since Computations live outside the widget tree,
/// [CorallineBuildContextAware] bridges this gap by providing a reactive [context] pipeline.
///
/// **Design Philosophy:**
/// Leverages an 'Intent-Driven Architecture' via [CorallineTerminalIntentAware]. By routing the
/// [BuildContext] as a topological intent from the UI layer to the business logic layer, the
/// Computation remains decoupled from Flutter's widget lifecycle while still maintaining complete
/// reactivity to dynamic UI changes (e.g., theme adjustments, screen resizing).
///
/// **AI & Developer Note:**
/// - **Do not cache the BuildContext:** Never save or store the emitted [BuildContext] inside
///   local fields. Only map or derive values reactively using [context]'s coral.
/// - **Deadlock Warning:** Ensure the Computation is mounted via a [CoralWidget] (using
///   `.toWidget()`); otherwise, the intent will not be delivered, and the context stream will
///   remain empty, causing a deadlock.
///
/// **Example:**
/// ```dart
/// class MyComponent extends CoralComponent with CorallineBuildContextAware {
///   late final themeCoral = context.map((ctx) => Theme.of(ctx));
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [themeCoral];
///
///   @override
///   Widget build() {
///     final theme = themeCoral.data;
///     return Container(color: theme.primaryColor);
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
  /// **AI & Developer Note (Broadcaster Line Warning):**
  /// - Reading [context] repeatedly or inside `compute()` without caching
  ///   creates separate unattached or dormant line instances.
  /// - Pulling data from an unattached line node will fail with a state error
  ///   ([CoralBroadcasterLineDormantAccessError]).
  /// - **Best Practice:** Always cache derived nodes in `late final` fields or
  ///   store the [context] instance before registering it in [manifest].
  ///
  /// **Example:**
  /// ```dart
  /// class MyComponent extends CoralComponent with CorallineBuildContextAware {
  ///   // Correct: Cache the derived line node as a late final field.
  ///   late final themeCoral = context.map((ctx) => Theme.of(ctx));
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [themeCoral];
  /// }
  /// ```
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
  /// **Design Philosophy:**
  /// Provides an extension point for Computations that require imperative lifecycle notifications
  /// when moving across different positions in Flutter's element tree.
  ///
  /// **Ensures:**
  /// * Invoked only when `!identical(oldContext, newContext)` at the element reference level.
  ///
  /// **AI & Developer Note:**
  /// - **No Direct Framework Rebuilds:** Calling `newContext?.dependOnInheritedWidgetOfExactType<T>()`
  ///   inside this hook will **NOT** automatically trigger an immediate widget rebuild.
  ///   [CoralWidgetElement] delegates computation to Coralline's lazy topological pipeline and
  ///   schedules a rebuild only when the reactive pipeline computes an updated UI subtree.
  /// - **Automatic Dependency Cleanup:** When the bound context or pipeline transitions,
  ///   tracked `InheritedElement` dependencies are automatically flushed (`_flushDependencies`)
  ///   to prevent ghost notifications and memory leaks.
  /// - **Do Not Cache Context:** Never store [newContext] in local mutable fields. Doing so
  ///   introduces stale element references and memory leaks.
  /// - **Reactivity Best Practice:** For UI dependencies (e.g., Theme, MediaQuery, InheritedWidgets),
  ///   use reactive context helpers (`context.theme`, `dependOn<T>()`, `coralOf<T>()`)
  ///   inside your Computation or `manifest()` rather than imperatively subscribing in this hook.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// void didUpdateBuildContext(BuildContext? oldContext, BuildContext? newContext) {
  ///   super.didUpdateBuildContext(oldContext, newContext);
  ///   // Perform setup or cleanup on element binding transition
  /// }
  /// ```
  void didUpdateBuildContext(
      BuildContext? oldContext, BuildContext? newContext) {}

  /// Creates a reactive [Coral] pipeline subscribing to an [InheritedWidget] of type [T] from the element tree.
  ///
  /// * [aspect]: Optional aspect identifier for fine-grained dependency tracking when [T] is an [InheritedModel].
  ///
  /// **Requires:**
  /// * An ancestor [InheritedWidget] of type [T] must exist in the element tree when the pipeline is evaluated.
  ///
  /// **Ensures:**
  /// * Automatically triggers [didChangeDependencies] and re-computes the pipeline whenever [T] (or [aspect]) updates.
  /// * Returns a non-null reactive [Coral<T>] pipeline emitting instances of [T].
  ///
  /// **Throws:**
  /// * Throws a null assertion error if no ancestor [InheritedWidget] of type [T] is found. Use [maybeDependOn] if optional.
  ///
  /// **Example:**
  /// ```dart
  /// class MyComponent extends ComplexComputation<Widget> with CorallineBuildContextAware {
  ///   late final themeCoral = dependOn<ThemeWidget>();
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
  /// * Automatically triggers [didChangeDependencies] and re-computes the pipeline whenever [T] (or [aspect]) updates.
  /// * Returns a reactive [Coral<T?>] pipeline emitting [T] or `null` if [T] is absent from the tree.
  ///
  /// **Example:**
  /// ```dart
  /// class MyComponent extends ComplexComputation<Widget> with CorallineBuildContextAware {
  ///   late final optionalThemeCoral = maybeDependOn<CustomThemeWidget>();
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
  /// **Key Architectural Advantages of `coralOf<T>()`:**
  /// 1. **Lazy Computation (Push-Dirty, Pull-Data)**: Eliminates UI frame drops (jank) by delaying computations strictly until frame render time.
  /// 2. **Context Decoupling via Intent Architecture**: Accesses ancestor state within business class fields without storing or leaking `BuildContext` references.
  /// 3. **Cascade Stream Flattening (2-Axis Unwrapping)**: Internally evaluates as:
  ///    `dependOn<InheritedCoralProviderWidget<T>>().cascade((data) => data.provider.coral)`
  ///    Flattens both ancestor tree position updates and internal state mutations into a single, unified [Coral<T>] stream.
  /// 4. **Topological Graph Safety (`@manifestSync`)**: Guarantees zero-over-fetching state synchronization when declared in `manifest()`.
  ///
  /// **Requires:**
  /// * An ancestor [InheritedCoralProviderWidget] providing type [T] must exist in the element tree.
  ///
  /// **Ensures:**
  /// * Automatically tracks changes to both the ancestor widget tree and the inner [Coral<T>] state.
  /// * Returns a non-null reactive [Coral<T>] pipeline.
  ///
  /// **Throws:**
  /// * Throws a null assertion error if no ancestor [InheritedCoralProviderWidget] of type [T] is found. Use [maybeCoralOf] if optional.
  ///
  /// **Example:**
  /// ```dart
  /// class CounterDisplay extends ComplexComputation<Widget> with CorallineBuildContextAware {
  ///   late final counterState = coralOf<CounterState>();
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
  /// **Cascade Stream Flattening:**
  /// Evaluates as `maybeDependOn<InheritedCoralProviderWidget<T>>().cascade((data) => data?.provider.coral ?? Coral.data(null))`.
  ///
  /// **Ensures:**
  /// * Automatically tracks changes to both the ancestor widget tree and the inner state.
  /// * Returns a reactive [Coral<T?>] pipeline emitting [T] or `null`.
  ///
  /// **Example:**
  /// ```dart
  /// class UserDisplay extends ComplexComputation<Widget> with CorallineBuildContextAware {
  ///   late final userState = maybeCoralOf<UserProfile>();
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
/// **Design Philosophy:**
/// Bridges reactive state providers with Flutter's element tree using Coralline's component lifecycle.
/// When [providerCoral] emits a new [CoralProvider], this component rebuilds the [InheritedCoralProviderWidget]
/// so that descendant computations reactively receive the updated provider.
///
/// **AI & Developer Note:**
/// - **Do Not Mutate `providerCoral` Directly:** Ensure [providerCoral] is registered in [manifest]
///   (automatically handled by [SimplexBuildComponent]) to guarantee reactive updates.
///
/// **Example:**
/// ```dart
/// final Coral<CoralProvider<UserStore>> providerCoral = ...;
/// final widget = InheritedCoralProvider(
///   providerCoral: providerCoral,
///   child: const HomeScreen(),
/// ).toWidget();
/// ```
base class InheritedCoralProvider<T> extends SimplexBuildComponent {
  InheritedCoralProvider({required this.providerCoral, required this.child});

  final Coral<CoralProvider<T>> providerCoral;

  final Widget child;

  @override
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
/// **Design Philosophy & Architectural System Benefits:**
/// Adheres to Flutter's native dependency propagation mechanism. It notifies dependent elements
/// only when the reference of [provider] changes (`oldWidget.provider != provider`).
/// 1. **Decoupled Layered Architecture**: Bridges pure Dart reactive logic ([CoralProvider])
///    with Flutter's element tree without coupling business logic to Flutter UI lifecycles.
/// 2. **Zero Prop-Drilling**: Eliminates deep prop-drilling by leveraging Flutter's $O(1)$
///    `dependOnInheritedWidgetOfExactType` element tree lookup mechanics.
/// 3. **Automatic Reactive Unwrapping**: Downstream components consume state via `coralOf<T>()`,
///    which flattens tree updates and inner [Coral] state changes into a unified stream.
/// 4. **Push-Dirty, Pull-Data Scheduling**: Aligns data propagation with Flutter's frame pipeline,
///    preventing unnecessary widget rebuilds and eliminating UI jank.
/// 5. **Lifecycle & Memory Safety**: Safely handles hot-swapping and element unmounting without
///    stale context leaks or memory leaks.
///
/// **System Architectural Flow:**
/// ```
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
/// **Architectural Rationale: Why Inherit [InheritedWidget] & Suppress Rebuilds?**
/// `InheritedCoralProviderWidget` directly extends Flutter's native [InheritedWidget] for 4 core reasons:
/// 1. **$O(1)$ Engine-Level Lookup Performance**: Leverages Flutter engine's internal `_inheritedElements`
///    HashMap via `dependOnInheritedWidgetOfExactType` for instant $O(1)$ ancestor lookups.
/// 2. **Zero-Leak Element Lifecycle Safety**: Automatically tracks and cleans up child element dependencies
///    (`removeDependent`) when widgets unmount, eliminating ghost memory leaks common in global service locators.
/// 3. **Seamless Ecosystem Compatibility**: Effortlessly bridges native Flutter UI context providers (`Theme`, `MediaQuery`)
///    into pure reactive [Coral] nodes via [CorallineBuildContextAware].
/// 4. **Rebuild Suppression Mechanics**: In [updateShouldNotify], it compares only `oldWidget.provider != provider`.
///    When inner data mutates, `updateShouldNotify` returns `false`, **suppressing Flutter's inefficient forced-rebuild
///    notification pipeline** and delegating all updates to Coralline's lazy push-dirty pull-data pipeline.
///
/// **Generic Type Selection Best Practices (Avoiding Type Shadowing):**
/// * **Use Strongly-Typed Domain Models:** `T` should be a unique domain model, store,
///   or state class (e.g., `UserStore`, `CartState`, `ThemeConfig`). Because Flutter looks up
///   [InheritedWidget] dependencies strictly by exact runtime type, using strongly-typed models
///   guarantees unambiguous element tree resolution.
/// * **Avoid Primitive Types (`int`, `String`, `bool`):** Do not use primitive or generic collection
///   types for `T`. If multiple primitive providers (e.g., `InheritedCoralProviderWidget<String>`)
///   exist in the ancestor tree, the lower provider will shadow the upper provider, causing
///   unintended lookup bugs. Wrap primitive values in dedicated domain value objects instead.
///
/// **Static & Dynamic Injection Strategy (Multi vs Single-Subscriber Rules):**
/// * **Multi-Subscriber Injection (Recommended for Widget Trees):** When a provider is injected into
///   the widget tree and multiple descendant components consume `coralOf<T>()` concurrently, wrap static
///   data with `CoralBroadcaster` (or set `broadcast: true` on `CoralController`). This enables 1:N
///   multi-cast fan-out and prevents single-subscriber ownership collision errors:
///   ```dart
///   final staticConfig = AppConfig(apiBaseUrl: 'https://api.example.com');
///   final appWidget = CoralBroadcaster.data(staticConfig).toInheritedWidget(
///     child: const MyApp(),
///   );
///   ```
/// * **Single-Subscriber Injection (Dedicated Single Consumer):** If guaranteed that only a single descendant
///   component consumes the state reactively via `coralOf<T>()`, you can wrap the raw static object directly using `CoralProvider.data`:
///   ```dart
///   final staticConfig = AppConfig(apiBaseUrl: 'https://api.example.com');
///   final singleWidget = CoralProvider.data(staticConfig).toInheritedWidget(
///     child: const MyApp(),
///   );
///   ```
/// * **Zero Performance Overhead:** `CoralProvider.data` creates a lightweight, static snapshot node.
///   Downstream components consume the state via `coralOf<T>()` with identical syntax, preserving complete
///   API uniformity if the data becomes dynamic in the future.
///
/// **AI & Developer Note:**
/// - **Convenience Extension:** Prefer using `provider.toInheritedWidget(child: ...)`
///   extension method for cleaner, fluid syntax.
///
/// **Example:**
/// ```dart
/// final CoralProvider<CounterState> provider = ...;
/// final widget = InheritedCoralProviderWidget<CounterState>(
///   provider: provider,
///   child: const MyApp(),
/// );
/// ```
class InheritedCoralProviderWidget<T> extends InheritedWidget {
  const InheritedCoralProviderWidget({
    required this.provider,
    required super.child,
    super.key,
  });

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
  /// **AI & Developer Note (App-Wide Fallback Pattern):**
  /// Create a project-specific extension (e.g. `toAppWidget()`) wrapping [toWidget] to encapsulate
  /// your design system's default error UI and global error logging (e.g., Sentry, Firebase)
  /// centrally across your application.
  ///
  /// **Example:**
  /// ```dart
  /// class CounterView extends BuildComponent { ... }
  /// final widget = CounterView().toWidget();
  ///
  /// // Custom App-Wide Fallback Extension Pattern:
  /// extension AppCoralWidgetExtension<T extends CoralComputation<Widget>> on T {
  ///   CoralWidget toAppWidget({
  ///     Key? key,
  ///     Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder,
  ///   }) {
  ///     return toWidget(
  ///       key: key,
  ///       errorBuilder: errorBuilder ?? (context, error, stackTrace) {
  ///         return AppStandardErrorCard(error: error); // Shared Design System Fallback
  ///       },
  ///     );
  ///   }
  /// }
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
  /// **Example:**
  /// ```dart
  /// final Coral<Widget> uiCoral = ...;
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
  /// **Example:**
  /// ```dart
  /// final CoralProvider<Widget> uiProvider = ...;
  /// final widget = uiProvider.toWidget();
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
  /// * [key]: Optional key for the [InheritedCoralProviderWidget].
  /// * [child]: The widget subtree below this provider in the element tree.
  ///
  /// **Design Philosophy & Architectural System Benefits:**
  /// 1. **Decoupled Layered Architecture**: Bridges pure Dart reactive logic ([CoralProvider])
  ///    with Flutter's element tree without coupling business logic to Flutter UI lifecycles.
  /// 2. **Zero Prop-Drilling**: Eliminates deep prop-drilling by leveraging Flutter's $O(1)$
  ///    `dependOnInheritedWidgetOfExactType` element tree lookup mechanics.
  /// 3. **Automatic Reactive Unwrapping**: Downstream components consume state via `coralOf<T>()`,
  ///    which flattens tree updates and inner [Coral] state changes into a unified stream.
  /// 4. **Push-Dirty, Pull-Data Scheduling**: Aligns data propagation with Flutter's frame pipeline,
  ///    preventing unnecessary widget rebuilds and eliminating UI jank.
  /// 5. **Lifecycle & Memory Safety**: Safely handles hot-swapping and element unmounting without
  ///    stale context leaks or memory leaks.
  ///
  /// **System Architectural Flow:**
  /// ```
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
  /// **Generic Type Selection Best Practices (Avoiding Type Shadowing):**
  /// * **Use Strongly-Typed Domain Models:** `T` should be a unique domain model, store,
  ///   or state class (e.g., `UserStore`, `CartState`, `ThemeConfig`). Because Flutter looks up
  ///   [InheritedWidget] dependencies strictly by exact runtime type, using strongly-typed models
  ///   guarantees unambiguous element tree resolution.
  /// * **Avoid Primitive Types (`int`, `String`, `bool`):** Do not use primitive or generic collection
  ///   types for `T`. If multiple primitive providers (e.g., `InheritedCoralProviderWidget<String>`)
  ///   exist in the ancestor tree, the lower provider will shadow the upper provider, causing
  ///   unintended lookup bugs. Wrap primitive values in dedicated domain value objects instead.
  ///
  /// **Static & Dynamic Injection Strategy (Multi vs Single-Subscriber Rules):**
  /// * **Multi-Subscriber Injection (Recommended for Widget Trees):** When a provider is injected into
  ///   the widget tree and multiple descendant components consume `coralOf<T>()` concurrently, wrap static
  ///   data with `CoralBroadcaster` (or set `broadcast: true` on `CoralController`). This enables 1:N
  ///   multi-cast fan-out and prevents single-subscriber ownership collision errors:
  ///   ```dart
  ///   final staticConfig = AppConfig(apiBaseUrl: 'https://api.example.com');
  ///   final appWidget = CoralBroadcaster.data(staticConfig).toInheritedWidget(
  ///     child: const MyApp(),
  ///   );
  ///   ```
  /// * **Single-Subscriber Injection (Dedicated Single Consumer):** If guaranteed that only a single descendant
  ///   component consumes the state reactively via `coralOf<T>()`, you can wrap the raw static object directly using `CoralProvider.data`:
  ///   ```dart
  ///   final staticConfig = AppConfig(apiBaseUrl: 'https://api.example.com');
  ///   final singleWidget = CoralProvider.data(staticConfig).toInheritedWidget(
  ///     child: const MyApp(),
  ///   );
  ///   ```
  /// * **Zero Performance Overhead:** `CoralProvider.data` creates a lightweight, static snapshot node.
  ///   Downstream components consume the state via `coralOf<T>()` with identical syntax, preserving complete
  ///   API uniformity if the data becomes dynamic in the future.
  ///
  /// **Use Cases:**
  /// * **Global or Feature Dependency Injection**: Easily inject reactive stores into the widget tree:
  ///   ```dart
  ///   final userStoreProvider = CoralProvider<UserStore>(...);
  ///   final appWidget = userStoreProvider.toInheritedWidget(child: const MyApp());
  ///   ```
  /// * **Prop-less Downstream Consumption**: Descendant computations consume the state reactively via [coralOf] without prop-drilling:
  ///   ```dart
  ///   class ProfileDisplay extends ComplexComputation<Widget> with CorallineBuildContextAware {
  ///     late final userStoreCoral = coralOf<UserStore>();
  ///   }
  ///   ```
  ///
  /// **Ensures:**
  /// * Returns a new [InheritedCoralProviderWidget<T>] containing this provider and [child].
  ///
  /// **Example:**
  /// ```dart
  /// final CoralProvider<CounterState> provider = ...;
  /// final widget = provider.toInheritedWidget(child: const MyApp());
  /// ```
  InheritedCoralProviderWidget<T> toInheritedWidget(
          {Key? key, required Widget child}) =>
      InheritedCoralProviderWidget<T>(key: key, provider: this, child: child);
}
