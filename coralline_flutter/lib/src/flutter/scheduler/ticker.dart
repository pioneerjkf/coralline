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
/// **Design Philosophy:**
/// Decouples ticker lifecycle management from Flutter's [StatefulWidget] tree, enabling
/// business logic components or custom view models with [CorallineLifecycleAware] and
/// [CorallineBuildContextAware] capabilities to host animations cleanly while remaining responsive
/// to lifecycle events and subtree ticker mode changes.
///
/// ⚠️ **AI & Developer Note:**
/// All created [Ticker]s must be disposed (typically via their managing animation controllers)
/// before [didDeactivate] is invoked. Active tickers remaining during deactivation will throw
/// an assertion error in debug mode to prevent ticker memory leaks.
///
/// **Example:**
/// ```dart
/// class MultiAnimationController extends CorallineLifecycleAware
///     with CorallineBuildContextAware, TickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController controller1;
///   late final AnimationController controller2;
///
///   void init() {
///     controller1 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
///     controller2 = AnimationController(vsync: this, duration: const Duration(seconds: 2));
///   }
///
///   @override
///   void didDeactivate() {
///     controller1.dispose();
///     controller2.dispose();
///     super.didDeactivate();
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
/// **Design Philosophy:**
/// Provides a lightweight, single-ticker allocation pattern for [CorallineLifecycleAware]
/// objects. Enforces single-use semantics to prevent accidental creation of extra tickers while
/// automatically propagating lifecycle state.
///
/// ⚠️ **AI & Developer Note:**
/// Calling [createTicker] more than once on the same instance will throw an assertion error in debug mode.
/// If multiple tickers are needed, use [TickerProviderCorallineLifecycleAwareMixin] instead.
/// The created ticker must be disposed before calling `super.didDeactivate()`.
///
/// **Example:**
/// ```dart
/// class SingleAnimationController extends CorallineLifecycleAware
///     with CorallineBuildContextAware, SingleTickerProviderCorallineLifecycleAwareMixin {
///   late final AnimationController controller;
///
///   void init() {
///     controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
///   }
///
///   @override
///   void didDeactivate() {
///     controller.dispose();
///     super.didDeactivate();
///   }
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
