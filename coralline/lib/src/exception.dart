// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// **Design Philosophy (Diagnostics):**
/// The Coralline framework establishes a clear boundary between recoverable runtime
/// failures and structural programming bugs:
///
/// * **Recoverable Failures (Exceptions)**: Implemented via [CorallineException].
///   These represent dynamic operational issues (e.g., extracting data from a damaged
///   or empty snapshot, or releasing an unattached joint). Because these can happen
///   due to external or dynamic state changes, they are designed to be caught or handled
///   gracefully. Their diagnostics focus on action-oriented troubleshooting ("To resolve" guides)
///   to safeguard Flutter UI building and prevent unhandled Red Screen crashes.
///
/// * **Structural Programmatic Bugs (Errors)**: Implemented via [StateError] subclasses
///   (e.g., [CoralNodeReentrancyError], [CorallineTopologyError], [CoralBroadcasterLineDormantAccessError]).
///   These represent violations of graph construction or update cycles (e.g., circular reentrancy).
///   They are treated as Fail-Fast programmatic errors that are meant to halt execution
///   during development, forcing immediate topology correction rather than attempting to recover.
@pragma('flutter:keep-to-string-in-subtypes')
abstract class CorallineException implements Exception {
  const CorallineException();
}

/// **Core Concept:**
/// Thrown when a topological connection rule is violated at runtime,
/// such as trying to release a node that is not attached to the joint.
class CoralNodeReleaseViolationException extends CorallineException {
  const CoralNodeReleaseViolationException(this.joint, this.coralNode);

  final Object joint;
  final CoralNode coralNode;

  @override
  String toString() => ''
      '[Dart/Topology] Release Violation: Cannot release $coralNode from $joint.\n'
      "Under Dart's Single Ownership rule in CoralNode, "
      'a node can only be attached to one parent joint at a time.\n'
      'Attempting to release or steal ownership of a node that is not '
      'attached to this joint leads to memory leaks and topological inconsistency.\n'
      'Ensure you call detach() on the active joint before attaching '
      'this node elsewhere.';
}

/// **Core Concept:**
/// Thrown when a developer attempts to extract data from an invalid
/// state (e.g., [isEmpty] or [isDamaged]) of a [CoralSnapshot] or [TrunkSnapshot].
class CoralSnapshotExtractionException extends CorallineException {
  const CoralSnapshotExtractionException(
    this.state,
    this.details, {
    this.error,
    this.stackTrace,
  });

  final String state;
  final String details;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln(''
          '[Global] Snapshot Extraction Failure: '
          'Attempted to extract .data from an invalid snapshot state ($state).')
      ..writeln(''
          'Extracting data from an Empty or Damaged state throws a Fail-Fast '
          'exception.')
      ..writeln(''
          'Context: $details');

    if (error != null) {
      buffer.writeln('\n======================================');
      buffer.writeln('🚨 ORIGINAL PIPELINE ERROR CAUSE:');
      buffer.writeln('$error');
      if (stackTrace != null && stackTrace != StackTrace.empty) {
        buffer.writeln('\nORIGINAL STACK TRACE:');
        buffer.writeln('$stackTrace');
      }
      buffer.writeln('======================================\n');
    }

    buffer.writeln('To resolve:');
    buffer.writeln("1. Safely handle the state using '.dataOrNull' or '.dataOrElse(() => fallback)'.");
    buffer.writeln("2. Verify the snapshot validity with '.isValid' or check '.error' if '.isDamaged' is true.");

    return buffer.toString();
  }
}

/// **Core Concept:**
/// Thrown when a developer attempts to query state metadata (like [error] or [stackTrace])
/// from a snapshot state where it does not exist (e.g., querying error on a valid snapshot).
class CoralSnapshotStateException extends CorallineException {
  const CoralSnapshotStateException(this.state, this.details);

  final String state;
  final String details;

  @override
  String toString() => ''
      '[Dart/API] Invalid State Access: Querying state metadata '
      '(error/stackTrace) from an incompatible state ($state).\n'
      "Under CoralNode's type-safe snapshot contracts, error and stackTrace "
      'metadata are only guaranteed to exist on a Damaged state.\n'
      'Context: $details\n'
      "Ensure '.isDamaged' is true before inspecting error metadata, "
      "or use '.isValid' / '.isEmpty' to check the state first.";
}

/// **Core Concept:**
/// Thrown when a reentrant call to `_pushDirty` is detected on a [_DirtyPoint].
/// This is a programmatic error indicating a cyclic update or structural bug.
class CoralNodeReentrancyError extends StateError {
  CoralNodeReentrancyError([String? message]) : super(message ?? 'Reentrant call to _pushDirty detected.');

  @override
  String toString() => ''
      '[Dart] Reentrancy Violation: $message\n'
      'A dirty point cannot push again while it is actively in its '
      'notification phase.\n'
      'This usually occurs when a downstream listener synchronously '
      'mutates or updates an upstream node during event propagation, '
      'causing an infinite update cycle.\n'
      'To resolve:\n'
      '1. Avoid synchronous circular mutations.\n'
      "2. If triggering from a UI framework state rebuild, defer the "
      "update using a post-frame/tick callback or "
      'an asynchronous event loop delay.';
}

/// **Core Concept:**
/// Thrown when a topological error is detected during graph construction or attachment,
/// such as placing an intent-aware Computation upstream of a broadcaster.
class CorallineTopologyError extends StateError {
  CorallineTopologyError([String? message]) : super(message ?? 'Intent Firewall Violation detected.');

  @override
  String toString() => ''
      '[Topology] Broadcaster Intent Firewall Violation: $message\n'
      'Broadcasters act as an Intent Firewall and drop all downstream '
      'intents to prevent 1:N collisions.\n'
      'Consequently, this upstream Computation will never receive intent updates.\n'
      'To resolve: Place this Computation on a downstream branch (after '
      'the broadcaster) so it can safely listen to private UI intents.';
}

/// **Core Concept:**
/// Thrown when a snapshot or computation query is executed on a dormant or deactivated [_BroadcasterLine].
/// This is a Fail-Fast lifecycle contract violation specific to broadcaster lines.
class CoralBroadcasterLineDormantAccessError extends StateError {
  CoralBroadcasterLineDormantAccessError(this.node, [String? details])
      : super(details ?? 'snapshot accessed on a dormant broadcaster line node.');

  final CoralNode node;

  @override
  String toString() => ''
      '[Broadcaster/Line] Dormant Line Access Violation: $message\n'
      'Target Line Node: $node\n'
      'Querying data from a non-running or dormant Broadcaster Line '
      'violates the Coralline lifecycle contract.\n'
      'Dormant lines are detached from their parent Broadcaster and cannot '
      'guarantee updated states or safe lazy computation.\n'
      'To resolve:\n'
      '1. Ensure the line node or its listener joint is active '
      '(isRunning == true) before pulling data.\n'
      '2. Query snapshot within an active lifecycle context '
      '(e.g., inside widget build or controller execution).';
}
