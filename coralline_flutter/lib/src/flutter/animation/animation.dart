part of '../../../animation.dart';

/// A state-resilient, lifecycle-managed [AnimationController] wrapper powered by [Coral].
///
/// [ResilientAnimationController] provides the full feature set of Flutter's
/// [AnimationController] while offering complete state resilience across resource lifecycle
/// drops. It defers actual engine creation until the underlying [Coral] resource is
/// activated, preserves parameters locally during dormant states, and restores state
/// seamlessly when reactivated or reset.
///
/// **Design Philosophy:**
/// This class adopts a resilient state-delegate pattern (`_DormantAnimationControlDelegate` and
/// `_ActiveAnimationControlDelegate`) to ensure state continuity and fault tolerance. When
/// dormant, parameter updates and state mutations are safely staged locally without
/// instantiating an active [AnimationController] engine or throwing state errors. When the
/// [coral] resource activates, delegates swap seamlessly into an active engine without breaking
/// existing listeners or property values. Furthermore, when the resource is deactivated, the
/// controller gracefully reverts back to a dormant state, demonstrating complete resilience
/// against lifecycle teardowns.
/// It also implements [CoralProvider<double>], optionally broadcasting value changes when
/// [broadcast] is `true`.
///
/// **AI & Developer Note:**
/// - Do not manually call `engine.dispose()` directly on the underlying [AnimationController].
///   Resource disposal must be handled via the [coral] lifecycle manager or [dispose].
/// - Parameter updates performed while dormant will be synchronized into the active engine
///   once instantiated.
/// - If [broadcast] is set to `true`, multiple subscribers can listen to the [coral] resource
///   without triggering duplicate resource initializations.
///
/// **Example:**
/// ```dart
/// base class ExpandablePanel extends ComplexComputation<Widget>
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         TickerProviderCorallineLifecycleAwareMixin {
///   ExpandablePanel({required this.child});
///
///   final Widget child;
///
///   static final Animatable<double> _expansionTween = CurveTween(
///     curve: Curves.easeInToLinear,
///   );
///
///   // 1. Initialize ResilientAnimationController using `this` as vsync TickerProvider.
///   late final controller = ResilientAnimationController(
///     duration: const Duration(milliseconds: 300),
///     vsync: this,
///   );
///
///   // 2. Pass controller through Animatable to create a transformed Animation.
///   late final animation = controller.drive(_expansionTween);
///
///   @override
///   Iterable<CoralNode> manifest() sync* {
///     // 3. Register controller.coral in the reactive node topology.
///     yield controller.coral;
///   }
///
///   @override
///   Widget build() {
///     // 4. Render animated transition with the transformed animation.
///     return SizeTransition(
///       sizeFactor: animation,
///       child: child,
///     );
///   }
/// }
/// ```
base class ResilientAnimationController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin
    implements CoralProvider<double> {
  /// Whether changes to the underlying [coral] resource are broadcasted to multiple subscribers.
  ///
  /// When `true`, uses a [CoralBroadcaster] to allow multiple listeners to share the same
  /// animation stream without re-activating the underlying resource. Defaults to `false`.
  final bool broadcast;

  /// The [TickerProvider] used to create the underlying [Ticker].
  TickerProvider vsync;

  /// A label used to identify this animation in debug output.
  final String? debugLabel;

  /// The value at which this animation is deemed to be dismissed.
  ///
  /// **Constraints:**
  /// Must be less than or equal to [upperBound].
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  ///
  /// **Constraints:**
  /// Must be greater than or equal to [lowerBound].
  final double upperBound;

  /// The behavior of the controller when system settings disable animations.
  final AnimationBehavior animationBehavior;

  late _AnimationControlDelegate _delegate;

  /// Creates a resilient animation controller with bounded limits.
  ///
  /// * [broadcast]: Whether to broadcast updates to multiple subscribers. Defaults to `false`.
  /// * [value]: The initial value of the animation. Defaults to [lowerBound].
  /// * [duration]: The length of time this animation should last.
  /// * [reverseDuration]: The length of time this animation should last when going in reverse.
  /// * [debugLabel]: A label used to identify this animation in debug output.
  /// * [lowerBound]: The minimum value for this animation. Defaults to `0.0`.
  /// * [upperBound]: The maximum value for this animation. Defaults to `1.0`.
  /// * [animationBehavior]: The behavior when animations are disabled by system settings.
  ///   Defaults to [AnimationBehavior.normal].
  /// * [vsync]: The [TickerProvider] for driving the animation ticker.
  ///
  /// **Requires:**
  /// * [upperBound] must be greater than or equal to [lowerBound].
  ///
  /// **Ensures:**
  /// * Initializes in a dormant state (`_DormantAnimationControlDelegate`) until the [coral]
  ///   resource is activated.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = ResilientAnimationController(
  ///   duration: const Duration(milliseconds: 300),
  ///   vsync: vsyncProvider,
  /// );
  /// ```
  ResilientAnimationController({
    this.broadcast = false,
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    this.debugLabel,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior = AnimationBehavior.normal,
    required this.vsync,
  }) : assert(upperBound >= lowerBound) {
    assert(debugMaybeDispatchCreated('animation', 'AnimationController', this));
    _delegate = _DormantAnimationControlDelegate(
      value: value ?? lowerBound,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
      onValueOrDurationChanged: notifyListeners,
    );
  }

  /// Creates a resilient animation controller with unbounded limits.
  ///
  /// Unbounded controllers have [lowerBound] set to [double.negativeInfinity]
  /// and [upperBound] set to [double.infinity].
  ///
  /// * [broadcast]: Whether to broadcast updates to multiple subscribers. Defaults to `false`.
  /// * [value]: The initial value of the animation. Defaults to `0.0`.
  /// * [duration]: The length of time this animation should last.
  /// * [reverseDuration]: The length of time this animation should last when going in reverse.
  /// * [debugLabel]: A label used to identify this animation in debug output.
  /// * [vsync]: The [TickerProvider] for driving the animation ticker.
  /// * [animationBehavior]: The behavior when animations are disabled by system settings.
  ///   Defaults to [AnimationBehavior.preserve].
  ///
  /// **Ensures:**
  /// * Initializes in a dormant state (`_DormantAnimationControlDelegate`) with infinite bounds.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = ResilientAnimationController.unbounded(
  ///   value: 10.0,
  ///   vsync: vsyncProvider,
  /// );
  /// ```
  ResilientAnimationController.unbounded({
    this.broadcast = false,
    double value = 0.0,
    Duration? duration,
    Duration? reverseDuration,
    this.debugLabel,
    required this.vsync,
    this.animationBehavior = AnimationBehavior.preserve,
  })  : lowerBound = double.negativeInfinity,
        upperBound = double.infinity {
    assert(debugMaybeDispatchCreated('animation', 'AnimationController', this));
    _delegate = _DormantAnimationControlDelegate(
      value: value,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
      onValueOrDurationChanged: notifyListeners,
    );
  }

  /// The underlying [Coral<AnimationController>] resource node.
  late final Coral<AnimationController> _resource = Coral.resource(
    create: () {
      final engine = AnimationController(
        value: _delegate.value,
        duration: _delegate.duration,
        reverseDuration: _delegate.reverseDuration,
        debugLabel: debugLabel,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
        vsync: vsync,
      );

      engine.addListener(notifyListeners);
      engine.addStatusListener(notifyStatusListeners);

      _delegate = _ActiveAnimationControlDelegate(engine);
      return engine;
    },
    dispose: (resource) {
      _delegate = _DormantAnimationControlDelegate(
        value: resource.value,
        duration: resource.duration,
        reverseDuration: resource.reverseDuration,
        lowerBound: lowerBound,
        upperBound: upperBound,
        onValueOrDurationChanged: notifyListeners,
      );
      resource.removeListener(notifyListeners);
      resource.removeStatusListener(notifyStatusListeners);
      resource.dispose();
    },
  );

  /// The internal [CoralProvider<double>] strategy (single-subscriber or broadcast).
  late final CoralProvider<double> _provider = (broadcast
      ? CoralBroadcaster(
          _resource.cascade((controller) => controller.toCoral()))
      : CoralProvider.coral(
          _resource.cascade((controller) => controller.toCoral())));

  /// The [Coral<double>] instance exposing the animated double value lifecycle.
  ///
  /// Cascades the underlying [AnimationController] resource to a [Coral<double>] stream/resource,
  /// fulfilling the [CoralProvider<double>] interface contract.
  @override
  Coral<double> get coral => _provider.coral;

  /// Whether the underlying animation [coral] resource node has been activated.
  ///
  /// **Ensures:**
  /// * Returns `true` if the active engine is instantiated and running within the [coral] lifecycle.
  /// * Returns `false` when dormant or deactivated.
  @override
  bool get isActivated => _resource.isActivated;

  /// Whether the underlying animation [coral] resource node has been permanently deactivated.
  ///
  /// **Ensures:**
  /// * Returns `true` if the [coral] resource node has terminated its lifecycle.
  @override
  bool get isDeactivated => _resource.isDeactivated;

  /// Whether the underlying animation [coral] resource node is temporarily paused.
  ///
  /// **Ensures:**
  /// * Returns `true` if paused by the [coral] lifecycle manager.
  @override
  bool get isPaused => _resource.isPaused;

  /// Whether the underlying animation [coral] resource node is currently running.
  ///
  /// **Ensures:**
  /// * Returns `true` if the active engine ticker is actively ticking.
  @override
  bool get isRunning => _resource.isRunning;

  /// Returns an [Animation<double>] view for this animation controller.
  ///
  /// Provides a read-only animation interface backed by the current delegate.
  /// Returns `null` when dormant.
  Animation<double>? get view => _delegate.view;

  /// The length of time this animation should last.
  ///
  /// Setting this value while dormant preserves the duration and notifies listeners.
  Duration? get duration => _delegate.duration;
  set duration(Duration? value) => _delegate.duration = value;

  /// The length of time this animation should last when going in reverse.
  ///
  /// Setting this value while dormant preserves the duration and notifies listeners.
  Duration? get reverseDuration => _delegate.reverseDuration;
  set reverseDuration(Duration? value) => _delegate.reverseDuration = value;

  /// Recreates the underlying ticker with a new [TickerProvider].
  ///
  /// * [vsync]: The new [TickerProvider] to sync ticker updates with.
  ///
  /// **Requires:**
  /// * [vsync] must be a non-null [TickerProvider].
  ///
  /// **Ensures:**
  /// * Updates the local [vsync] property and notifies the underlying state delegate.
  ///
  /// **Example:**
  /// ```dart
  /// controller.resync(newVsyncProvider);
  /// ```
  void resync(TickerProvider vsync) {
    this.vsync = vsync;
    _delegate.resync(vsync);
  }

  /// The current value of the animation.
  ///
  /// **Constraints:**
  /// For bounded controllers, this value is bounded by [lowerBound] and [upperBound].
  @override
  double get value => _delegate.value;

  /// Stops the animation controller and sets the current value of the animation.
  ///
  /// * [newValue]: The new animation progress value to set immediately.
  ///
  /// **Ensures:**
  /// * Cancels any active simulation and sets [value] to [newValue].
  set value(double newValue) => _delegate.value = newValue;

  /// Sets the controller's value to [lowerBound], stopping the animation.
  ///
  /// **Ensures:**
  /// * Stops any running simulation and resets [value] to [lowerBound].
  ///
  /// **Example:**
  /// ```dart
  /// controller.reset();
  /// ```
  void reset() => _delegate.reset();

  /// The rate of change of [value] per second.
  ///
  /// Returns `0.0` if dormant or if no animation is currently running.
  double get velocity => _delegate.velocity;

  /// The amount of time that has elapsed since the animation started.
  ///
  /// Returns `null` if dormant or if the animation has not started ticking yet.
  Duration? get lastElapsedDuration => _delegate.lastElapsedDuration;

  /// Whether this animation is currently animating.
  ///
  /// Returns `false` when dormant.
  @override
  bool get isAnimating => _delegate.isAnimating;

  /// The current status of this animation.
  ///
  /// When dormant, returns [AnimationStatus.completed] if [value] == [upperBound],
  /// otherwise returns [AnimationStatus.dismissed].
  @override
  AnimationStatus get status => _delegate.status;

  /// Whether this animation is stopped at the beginning ([status] is [AnimationStatus.dismissed]).
  @override
  bool get isDismissed => status.isDismissed;

  /// Whether this animation is stopped at the end ([status] is [AnimationStatus.completed]).
  @override
  bool get isCompleted => status.isCompleted;

  /// Whether the current aim of the animation is toward completion.
  @override
  bool get isForwardOrCompleted => status.isForwardOrCompleted;

  /// Starts running this animation forwards (towards the end).
  ///
  /// * [from]: Optional starting value. If omitted, continues from current [value].
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Ensures:**
  /// * Activates ticker simulation toward [upperBound].
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.forward(from: 0.0);
  /// ```
  @awaitNotRequired
  TickerFuture forward({double? from}) => _delegate.forward(from: from);

  /// Starts running this animation in reverse (towards the beginning).
  ///
  /// * [from]: Optional starting value. If omitted, continues from current [value].
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Ensures:**
  /// * Activates ticker simulation toward [lowerBound].
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.reverse(from: 1.0);
  /// ```
  @awaitNotRequired
  TickerFuture reverse({double? from}) => _delegate.reverse(from: from);

  /// Toggles the direction of this animation.
  ///
  /// If [isCompleted] or moving forward, runs in reverse. Otherwise runs forward.
  ///
  /// * [from]: Optional starting value.
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the animation reaches the destination bound.
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.toggle();
  /// ```
  @awaitNotRequired
  TickerFuture toggle({double? from}) => _delegate.toggle(from: from);

  /// Drives the animation from its current value to the given target, "forward".
  ///
  /// * [target]: The target value to animate towards.
  /// * [duration]: The duration over which to animate. If null, calculates duration proportionally.
  /// * [curve]: The curve to apply during animation. Defaults to [Curves.linear].
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the animation reaches [target].
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.animateTo(0.8, duration: const Duration(milliseconds: 200));
  /// ```
  @awaitNotRequired
  TickerFuture animateTo(double target,
          {Duration? duration, Curve curve = Curves.linear}) =>
      _delegate.animateTo(target, duration: duration, curve: curve);

  /// Drives the animation from its current value to the given target, "backward".
  ///
  /// * [target]: The target value to animate towards in reverse.
  /// * [duration]: The duration over which to animate. If null, calculates duration proportionally.
  /// * [curve]: The curve to apply during animation. Defaults to [Curves.linear].
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the animation reaches [target].
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.animateBack(0.2);
  /// ```
  @awaitNotRequired
  TickerFuture animateBack(double target,
          {Duration? duration, Curve curve = Curves.linear}) =>
      _delegate.animateBack(target, duration: duration, curve: curve);

  /// Starts running this animation in the forward direction, and restarts when complete.
  ///
  /// * [min]: Minimum value during repetition. Defaults to [lowerBound].
  /// * [max]: Maximum value during repetition. Defaults to [upperBound].
  /// * [reverse]: Whether the animation alternates direction on each pass. Defaults to `false`.
  /// * [period]: Optional duration for each repetition pass.
  /// * [count]: Optional maximum number of repetition cycles before stopping.
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that never completes naturally while repeating indefinitely, or completes
  /// after [count] cycles.
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.repeat(reverse: true);
  /// ```
  @awaitNotRequired
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) =>
      _delegate.repeat(
          min: min, max: max, reverse: reverse, period: period, count: count);

  /// Drives the animation with a spring and initial velocity.
  ///
  /// * [velocity]: The initial velocity in units per second. Defaults to `1.0`.
  /// * [springDescription]: Custom spring parameters.
  /// * [animationBehavior]: Custom animation behavior override.
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the spring simulation comes to rest.
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.fling(velocity: 2.0);
  /// ```
  @awaitNotRequired
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) =>
      _delegate.fling(
          velocity: velocity,
          springDescription: springDescription,
          animationBehavior: animationBehavior);

  /// Drives the animation according to the given simulation.
  ///
  /// * [simulation]: The physics simulation defining motion over time.
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the simulation finishes.
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.animateWith(customSimulation);
  /// ```
  @awaitNotRequired
  TickerFuture animateWith(Simulation simulation) =>
      _delegate.animateWith(simulation);

  /// Drives the animation according to the given simulation with a status of reverse.
  ///
  /// * [simulation]: The physics simulation defining motion over time.
  ///
  /// **Requires:**
  /// * Controller must be activated by a [Coral] resource topology before driving motion.
  ///
  /// **Returns:**
  /// A [TickerFuture] that completes when the simulation finishes.
  ///
  /// **Throws:**
  /// * [StateError] if invoked while in a dormant state.
  ///
  /// **Example:**
  /// ```dart
  /// controller.animateBackWith(customSimulation);
  /// ```
  @awaitNotRequired
  TickerFuture animateBackWith(Simulation simulation) =>
      _delegate.animateBackWith(simulation);

  /// Stops running this animation.
  ///
  /// * [canceled]: Whether active animation futures should be completed with an exception.
  ///   Defaults to `true`.
  ///
  /// **Ensures:**
  /// * Stops the ticker and prevents further listener notifications until restarted.
  ///
  /// **Example:**
  /// ```dart
  /// controller.stop();
  /// ```
  void stop({bool canceled = true}) => _delegate.stop(canceled: canceled);

  /// Releases the resources used by this object.
  ///
  /// **Ensures:**
  /// * Disposes the active or dormant delegate and notifies parent listeners.
  ///
  /// **AI & Developer Note:**
  /// After calling [dispose], this controller cannot be reused.
  ///
  /// **Example:**
  /// ```dart
  /// controller.dispose();
  /// ```
  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  /// Passes this animation through an [Animatable] to create a transformed [Animation].
  ///
  /// * [child]: The [Animatable] transformation (e.g. [Tween]) to apply.
  ///
  /// **Returns:**
  /// A new [Animation] reflecting the transformed values of this controller.
  ///
  /// **Example:**
  /// ```dart
  /// final animation = controller.drive(Tween<double>(begin: 0.0, end: 100.0));
  /// ```
  @override
  Animation<U> drive<U>(Animatable<U> child) => child.animate(this);

  /// Returns detailed diagnostic string representation for debug output.
  @override
  String toStringDetails() => _delegate.toStringDetails();
}
