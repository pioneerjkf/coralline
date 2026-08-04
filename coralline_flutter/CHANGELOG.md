## 0.1.4

### Refactoring & Fixes
- Update `coralline` and `coralline_extensions` dependency constraints to `^0.1.2`.
- Ensure robust uncaught error handling integration with upgraded `coralline 0.1.2` core engine.

### Tests
- Add comprehensive unit tests for `BuildContext` proxies and reactive lifecycle hooks.

## 0.1.3

- Remove `@awaitNotRequired` annotations from animation controller delegates to maintain 100% static analysis compatibility with Flutter SDK (`meta: ^1.18.0`).

## 0.1.2

- Add comprehensive Architecture Deep Dive documentation (`doc/architecture_analysis.md`).
- Update core and extensions dependency constraints to `^0.1.1`.

## 0.1.1

- Align `meta` package version constraint (`^1.18.0`) with Flutter SDK pinned dependencies.

## 0.1.0

- Initial release of Coralline Flutter state management framework.
- High-performance reactive UI components: `SimplexBuildComponent` and `BuildComponent`.
- Intent-driven context propagation via `CorallineBuildContextAware`.
- Zero prop-drilling dependency injection with `InheritedCoralProviderWidget` and `coralOf<T>()`.
- Animation controller and Ticker integration for Flutter UI elements.
