## 0.1.3

### Fixes
- Safely dispose existing valid resource snapshots before re-creating resources upon `Coral.resource` node activation.

## 0.1.2

### Performance
- Coalesce entry coral dirty notifications until snapshot pull to minimize evaluation overhead in deep reactive chains.

### Added
- Add `cast` and `toUnmodifiable` proxy methods to `Coral` collection elements.

### Refactoring & Fixes
- Prevent assertion cascades in error handlers when custom intents fail by using clean debug logging (`print`).
- Rename async extension classes for internal naming consistency.

### Documentation
- Clean up manual docs: remove obsolete mandatory disposal notes, `onDirty` anti-pattern warnings, and frame scheduling specifics.

## 0.1.1

- Align `meta` package version constraint (`^1.18.0`) for maximum Flutter and Dart SDK compatibility.

## 0.1.0

- Initial release of Coralline core library.
- Implementation of Chain of Reactivity and Lazy-computation Pipeline (CORAL) architecture.
- Core reactive building blocks: `CoralController`, `Coral`, `Trunk`, `CoralTerminal`, and `CoralSnapshot`.
