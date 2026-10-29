// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../scheduler.dart';

/// Internal [Ticker] subclass that notifies its parent [TickerProviderCorallineLifecycleAwareMixin]
/// upon disposal to automatically clean up references.
class _CorallineLifecycleTicker extends Ticker {
  _CorallineLifecycleTicker(super.onTick, this._creator, {super.debugLabel});

  final TickerProviderCorallineLifecycleAwareMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

/// Provides multiple [Ticker] instances for non-widget [CorallineLifecycleAware] objects.
///
/// Analogous to Flutter's [TickerProviderStateMixin], this mixin acts as a [TickerProvider]
/// bound to the lifecycle of a [CorallineLifecycleAware] component. It automatically
/// synchronizes all created tickers with app lifecycle transitions (pausing/resuming)
/// and tree [TickerMode] states.
///
/// ## Lifecycle Flow Diagram
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │         Coralline Ticker Provider Lifecycle            │
/// └────────────────────────────────────────────────────────┘
///       │
///       ▼ didActivate()
/// [Tickers Active] <─── didResume() ──┐
///       │                             │
///       ▼ didPause()                  │
/// [Tickers Muted] ────────────────────┘
///       │
///       ▼ didDeactivate()
/// [All Tickers Disposed / Assert Cleaned]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Decoupled Business Logic**: Decouples animation ticker orchestration from Flutter's
///    widget tree, allowing view models and controllers to manage tickers safely.
/// 2. **Automatic Lifecycle Synchronization**: Synchronizes ticker mute states automatically
///    with [didPause] and [didResume] lifecycle hooks.
/// 3. **Subtree Ticker Mode Awareness**: Dynamically listens to ancestor [TickerMode] changes
///    via [didUpdateBuildContext].
///
/// **Warning (Anti-Pattern Prevention):**
/// - Failing to dispose animation controllers before [didDeactivate] leads to ticker leaks and
///   debug assertions.
/// - Do not manually mute tickers directly; rely on Coralline's lifecycle methods.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Omitting animation controller disposal in didDeactivate
/// base class LeakingAnimationComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         TickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController controller = AnimationController(
///     vsync: this,
///     duration: const Duration(seconds: 1),
///   );
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() => FadeTransition(opacity: controller, child: const SizedBox());
///   // didDeactivate is missing controller.dispose(), triggering a debug assertion error!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Explicitly dispose all controllers in didDeactivate before calling super
/// base class CleanAnimationComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         TickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController controller = AnimationController(
///     vsync: this,
///     duration: const Duration(seconds: 1),
///   );
///
///   @override
///   void didDeactivate() {
///     controller.dispose();
///     super.didDeactivate();
///   }
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() => FadeTransition(opacity: controller, child: const SizedBox());
/// }
/// ```
///
/// ## Examples
/// ```dart
/// base class MultiAnimationComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         TickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController fadeController = AnimationController(
///     vsync: this,
///     duration: const Duration(seconds: 1),
///   );
///   late final AnimationController scaleController = AnimationController(
///     vsync: this,
///     duration: const Duration(seconds: 2),
///   );
///
///   @override
///   void didDeactivate() {
///     fadeController.dispose();
///     scaleController.dispose();
///     super.didDeactivate();
///   }
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() {
///     return ScaleTransition(
///       scale: scaleController,
///       child: FadeTransition(opacity: fadeController, child: const SizedBox()),
///     );
///   }
/// }
/// ```
base mixin TickerProviderCorallineLifecycleAwareMixin
    on CorallineLifecycleAware, CorallineBuildContextAware
    implements TickerProvider {
  Set<Ticker>? _tickers;
  bool _muted = false;
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @mustCallSuper
  @override
  void didUpdateBuildContext(
      BuildContext? oldContext, BuildContext? newContext) {
    super.didUpdateBuildContext(oldContext, newContext);
    _updateTickerModeNotifier(newContext);
  }

  @mustCallSuper
  @override
  void didActivate() {
    super.didActivate();
    _muted = false;
    _updateTickers();
  }

  @mustCallSuper
  @override
  void didPause() {
    super.didPause();
    _muted = true;
    _updateTickers();
  }

  @mustCallSuper
  @override
  void didResume() {
    super.didResume();
    _muted = false;
    _updateTickers();
  }

  @mustCallSuper
  @override
  void didDeactivate() {
    assert(() {
      if (_tickers != null) {
        for (final Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was deactivated with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its TickerProviderCorallineLifecycleAwareMixin, '
                'but at the time didDeactivate() was called on the mixin, that Ticker was still active. '
                'All Tickers must be disposed before calling super.didDeactivate().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.didDeactivate();
  }

  /// Creates a new [Ticker] managed by this provider.
  ///
  /// * [onTick]: The callback to invoke on each animation frame.
  ///
  /// **Ensures:**
  /// * The returned [Ticker] is pre-configured with the current lifecycle mute state
  ///   and [TickerMode] settings.
  /// * Automatically registers the ticker so its state is updated when lifecycle
  ///   or ticker mode changes occur.
  ///
  /// **Side Effects:**
  /// * Adds the newly created ticker to the internal active ticker set.
  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_CorallineLifecycleTicker>{};
    final TickerModeData? values = _tickerModeNotifier?.value;
    final bool effectiveMuted = _muted || !(values?.enabled ?? true);
    final _CorallineLifecycleTicker result = _CorallineLifecycleTicker(
      onTick,
      this,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    )
      ..muted = effectiveMuted
      ..forceFrames = values?.forceFrames ?? false;
    _tickers!.add(result);
    return result;
  }

  /// Updates the internal [TickerMode] listener when the bound [BuildContext] updates.
  ///
  /// * [context]: The new [BuildContext] to listen to for [TickerMode] changes.
  ///
  /// **Ensures:**
  /// * Rebinds the internal [TickerMode] listener to [context]'s notifier.
  /// * Immediately updates all managed tickers with the latest [TickerModeData].
  void updateTickerModeNotifier(BuildContext? context) {
    _updateTickerModeNotifier(context);
  }

  void _removeTicker(_CorallineLifecycleTicker ticker) {
    if (_tickers != null) {
      assert(_tickers!.contains(ticker));
      _tickers!.remove(ticker);
    }
  }

  void _updateTickers() {
    if (_tickers != null) {
      final TickerModeData? values = _tickerModeNotifier?.value;
      final bool effectiveMuted = _muted || !(values?.enabled ?? true);
      final bool forceFrames = values?.forceFrames ?? false;
      for (final Ticker ticker in _tickers!) {
        ticker.muted = effectiveMuted;
        ticker.forceFrames = forceFrames;
      }
    }
  }

  void _updateTickerModeNotifier(BuildContext? context) {
    final ValueListenable<TickerModeData>? newNotifier =
        context != null && context.mounted
            ? TickerMode.getValuesNotifier(context)
            : null;
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier?.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
    _updateTickers();
  }
}

/// Provides a single [Ticker] instance for non-widget [CorallineLifecycleAware] objects.
///
/// Analogous to Flutter's [SingleTickerProviderStateMixin], this mixin acts as a [TickerProvider]
/// optimized for components that require exactly one animation controller. It automatically
/// synchronizes the ticker with app lifecycle transitions (pausing/resuming) and tree [TickerMode] states.
///
/// ## Lifecycle Flow Diagram
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │      Single Ticker Provider Lifecycle Transition       │
/// └────────────────────────────────────────────────────────┘
///       │
///       ▼ createTicker() [Allocates exactly one instance]
/// [Active Ticker] <─── didResume() ──┐
///       │                            │
///       ▼ didPause()                 │
/// [Muted Ticker] ────────────────────┘
///       │
///       ▼ didDeactivate()
/// [Ticker Disposed / Assert Cleaned]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero-Overhead Single Ticker**: Optimized for components hosting exactly one animation controller.
/// 2. **Single-Use Assertion Guard**: Calling [createTicker] more than once throws an assertion error,
///    preventing accidental multi-ticker leakage.
/// 3. **Subtree Ticker Mode Awareness**: Dynamically synchronizes frame ticking with ancestor [TickerMode].
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT create multiple animation controllers or call [createTicker] multiple times with this mixin.
/// - If a component needs 2 or more tickers, use [TickerProviderCorallineLifecycleAwareMixin].
/// - The created ticker must be disposed before calling `super.didDeactivate()`.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Attempting to create two tickers on a single-ticker mixin
/// base class DoubleAnimationComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         SingleTickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController c1 = AnimationController(vsync: this);
///   late final AnimationController c2 = AnimationController(vsync: this); // Debug assertion error!
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() => const SizedBox();
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use SingleTickerProviderCorallineLifecycleAwareMixin strictly for 1 ticker
/// base class SingleAnimationComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         SingleTickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController controller = AnimationController(
///     vsync: this,
///     duration: const Duration(milliseconds: 300),
///   );
///
///   @override
///   void didDeactivate() {
///     controller.dispose();
///     super.didDeactivate();
///   }
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Widget build() => FadeTransition(opacity: controller, child: const SizedBox());
/// }
/// ```
///
/// ## Examples
/// ```dart
/// base class PulsingBadgeComp extends BuildComponent
///     with
///         CorallineLifecycleAware,
///         CorallineTerminalIntentAware,
///         CorallineBuildContextAware,
///         SingleTickerProviderCorallineLifecycleAwareMixin {
///   PulsingBadgeComp({required this.labelCoral});
///   final Coral<String> labelCoral;
///
///   late final AnimationController pulseController = AnimationController(
///     vsync: this,
///     duration: const Duration(milliseconds: 400),
///   );
///
///   @override
///   void didActivate() {
///     super.didActivate();
///     pulseController.repeat(reverse: true);
///   }
///
///   @override
///   void didDeactivate() {
///     pulseController.dispose();
///     super.didDeactivate();
///   }
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [labelCoral];
///
///   @override
///   Widget build() => FadeTransition(
///     opacity: pulseController,
///     child: Text(labelCoral.data),
///   );
/// }
/// ```
base mixin SingleTickerProviderCorallineLifecycleAwareMixin
    on CorallineLifecycleAware, CorallineBuildContextAware
    implements TickerProvider {
  Ticker? _ticker;
  bool _muted = false;
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @mustCallSuper
  @override
  void didUpdateBuildContext(
      BuildContext? oldContext, BuildContext? newContext) {
    super.didUpdateBuildContext(oldContext, newContext);
    _updateTickerModeNotifier(newContext);
  }

  @mustCallSuper
  @override
  void didActivate() {
    super.didActivate();
    _muted = false;
    _updateTicker();
  }

  @mustCallSuper
  @override
  void didPause() {
    super.didPause();
    _muted = true;
    _updateTicker();
  }

  @mustCallSuper
  @override
  void didResume() {
    super.didResume();
    _muted = false;
    _updateTicker();
  }

  @mustCallSuper
  @override
  void didDeactivate() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was deactivated with an active Ticker.'),
        ErrorDescription(
          '$runtimeType created a Ticker via its SingleTickerProviderCorallineLifecycleAwareMixin, '
          'but at the time didDeactivate() was called on the mixin, that Ticker was still active. '
          'The Ticker must be disposed before calling super.didDeactivate().',
        ),
        ErrorHint(
          'Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.',
        ),
        _ticker!.describeForError('The offending ticker was'),
      ]);
    }());
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    super.didDeactivate();
  }

  /// Creates the single [Ticker] managed by this provider.
  ///
  /// * [onTick]: The callback to invoke on each animation frame.
  ///
  /// **Requires:**
  /// * Must not be called more than once per mixin instance.
  ///
  /// **Ensures:**
  /// * The returned [Ticker] is pre-configured with the current lifecycle mute state
  ///   and [TickerMode] settings.
  ///
  /// **Throws:**
  /// * Throws an assertion error in debug mode if called multiple times.
  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          '$runtimeType is a SingleTickerProviderCorallineLifecycleAwareMixin but multiple tickers were created.',
        ),
        ErrorDescription(
          'A SingleTickerProviderCorallineLifecycleAwareMixin can only be used as a TickerProvider once.',
        ),
        ErrorHint(
          'If a CorallineLifecycleAware object is used for multiple AnimationController objects, '
          'use TickerProviderCorallineLifecycleAwareMixin instead.',
        ),
      ]);
    }());
    final TickerModeData? values = _tickerModeNotifier?.value;
    final bool effectiveMuted = _muted || !(values?.enabled ?? true);
    _ticker = Ticker(
      onTick,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    )
      ..muted = effectiveMuted
      ..forceFrames = values?.forceFrames ?? false;
    return _ticker!;
  }

  /// Updates the internal [TickerMode] listener when the bound [BuildContext] updates.
  ///
  /// * [context]: The new [BuildContext] to listen to for [TickerMode] changes.
  ///
  /// **Ensures:**
  /// * Rebinds the internal [TickerMode] listener to [context]'s notifier.
  /// * Immediately updates the managed ticker with the latest [TickerModeData].
  void updateTickerModeNotifier(BuildContext? context) {
    _updateTickerModeNotifier(context);
  }

  void _updateTicker() {
    if (_ticker != null) {
      final TickerModeData? values = _tickerModeNotifier?.value;
      final bool effectiveMuted = _muted || !(values?.enabled ?? true);
      _ticker!.muted = effectiveMuted;
      _ticker!.forceFrames = values?.forceFrames ?? false;
    }
  }

  void _updateTickerModeNotifier(BuildContext? context) {
    final ValueListenable<TickerModeData>? newNotifier =
        context != null && context.mounted
            ? TickerMode.getValuesNotifier(context)
            : null;
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTicker);
    newNotifier?.addListener(_updateTicker);
    _tickerModeNotifier = newNotifier;
    _updateTicker();
  }
}
