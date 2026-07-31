// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../widgets.dart';

// =============================================================================
// Coral<BuildContext> Public Extensions
// =============================================================================

/// Reactive getters on [Coral<BuildContext>] for Flutter icon theme tokens.
extension CoralBuildContextIconThemeExtension on Coral<BuildContext> {
  /// Reactively observes the current [IconThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [IconThemeData] derived from the active element context.
  ///
  /// **AI & Developer Note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<IconThemeData> get iconTheme => map((e) => IconTheme.of(e)).distinct();
}

/// Reactive getters on [Coral<BuildContext>] for fine-grained [MediaQuery] environment properties.
extension CoralBuildContextMediaQueryExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for operating on [MediaQueryData] reactively.
  CoralBuildContextMediaQueryProxy get mediaQuery =>
      CoralBuildContextMediaQueryProxy._(this);
}

/// Reactive getters on [Coral<BuildContext>] for default text styling.
extension CoralBuildContextTextExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for default text styling reactively.
  CoralBuildContextTextProxy get text => CoralBuildContextTextProxy._(this);
}

/// Reactive getters on [Coral<BuildContext>] for localizations and text/layout directionality.
extension CoralBuildContextLocalizationExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for localizations and directionality properties reactively.
  CoralBuildContextLocalizationProxy get localization =>
      CoralBuildContextLocalizationProxy._(this);
}

/// Reactive getters on [Coral<BuildContext>] for focus, form, navigation, and UI scope controllers.
extension CoralBuildContextScopeExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for UI scope controllers reactively.
  CoralBuildContextScopeProxy get scope => CoralBuildContextScopeProxy._(this);
}

// =============================================================================
// Coral<BuildContext> Scope & Namespace Proxy Classes
// =============================================================================

/// **Core Concept (MediaQuery Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access fine-grained [MediaQuery] properties reactively.
extension type CoralBuildContextMediaQueryProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the complete [MediaQueryData].
  Coral<MediaQueryData> get data =>
      _coral.map((e) => MediaQuery.of(e)).distinct();

  /// Reactively observes screen or layout container size changes only.
  Coral<Size> get size => _coral.map((e) => MediaQuery.sizeOf(e)).distinct();

  /// Reactively observes safe area padding changes only.
  Coral<EdgeInsets> get padding =>
      _coral.map((e) => MediaQuery.paddingOf(e)).distinct();

  /// Reactively observes view insets changes only (e.g., software keyboard visibility).
  Coral<EdgeInsets> get viewInsets =>
      _coral.map((e) => MediaQuery.viewInsetsOf(e)).distinct();

  /// Reactively observes view padding changes only.
  Coral<EdgeInsets> get viewPadding =>
      _coral.map((e) => MediaQuery.viewPaddingOf(e)).distinct();

  /// Reactively observes screen orientation changes only.
  Coral<Orientation> get orientation =>
      _coral.map((e) => MediaQuery.orientationOf(e)).distinct();

  /// Reactively observes platform brightness changes only (light/dark mode).
  Coral<Brightness> get platformBrightness =>
      _coral.map((e) => MediaQuery.platformBrightnessOf(e)).distinct();

  /// Reactively observes device pixel ratio changes.
  Coral<double> get devicePixelRatio =>
      _coral.map((e) => MediaQuery.devicePixelRatioOf(e)).distinct();
}

/// **Core Concept (Text Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access text styling properties reactively.
extension type CoralBuildContextTextProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the default [DefaultTextStyle].
  Coral<DefaultTextStyle> get defaultStyle =>
      _coral.map((e) => DefaultTextStyle.of(e)).distinct();
}

/// **Core Concept (Localization Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access locale and directionality properties reactively.
extension type CoralBuildContextLocalizationProxy._(
    Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the active [Locale].
  Coral<Locale> get locale =>
      _coral.map((e) => Localizations.localeOf(e)).distinct();

  /// Reactively observes the current [TextDirection] (LTR / RTL).
  Coral<TextDirection> get direction =>
      _coral.map((e) => Directionality.of(e)).distinct();
}

/// **Core Concept (Scope Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access focus, form, navigation, and scroll scope controllers reactively.
///
/// **Scope Isolation Note:**
/// Only core Flutter widget framework scope controllers (`widgets.dart`) are exposed here.
/// Material- or Cupertino-specific scope features are excluded.
extension type CoralBuildContextScopeProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the current [FocusScopeNode].
  Coral<FocusScopeNode> get focus =>
      _coral.map((e) => FocusScope.of(e)).distinct();

  /// Reactively observes the nearest ancestor [FormState] if present.
  Coral<FormState?> get form => _coral.map((e) => Form.maybeOf(e)).distinct();

  /// Reactively observes the nearest [PrimaryScrollController] if bound.
  Coral<ScrollController?> get primaryScrollController =>
      _coral.map((e) => PrimaryScrollController.maybeOf(e)).distinct();

  /// Reactively observes the nearest ancestor [NavigatorState] if present.
  Coral<NavigatorState?> get navigator =>
      _coral.map((e) => Navigator.maybeOf(e)).distinct();

  /// Reactively observes the nearest ancestor [OverlayState] if present.
  Coral<OverlayState?> get overlay =>
      _coral.map((e) => Overlay.maybeOf(e)).distinct();

  /// Reactively observes the nearest ancestor [ScrollableState] if present.
  Coral<ScrollableState?> get scrollable =>
      _coral.map((e) => Scrollable.maybeOf(e)).distinct();
}
