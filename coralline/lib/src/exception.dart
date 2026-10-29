// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// The base class for all recoverable exceptions in the Coralline framework.
///
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
  /// Creates a recoverable Coralline framework exception.
  const CorallineException();
}

/// Thrown when a topological single-ownership connection rule is violated at runtime.
///
/// Occurs when trying to release or detach a node that is not currently attached to the joint.
class CoralNodeReleaseViolationException extends CorallineException {
  /// Creates a [CoralNodeReleaseViolationException] for [coralNode] and [joint].
  ///
  /// * [joint]: The parent joint or container that attempted the invalid release.
  /// * [coralNode]: The node whose ownership rule was violated.
  const CoralNodeReleaseViolationException(this.joint, this.coralNode);

  /// The parent joint or container that attempted the invalid release.
  final Object joint;

  /// The [CoralNode] whose single-ownership contract was violated.
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

/// Thrown when attempting to extract data from an uninitialized or damaged snapshot state.
///
/// Fails fast when accessing [CoralSnapshot.data] or [TrunkSnapshot.lines] on an
/// [CorallineSnapshot.isEmpty] or [CorallineSnapshot.isDamaged] snapshot.
class CoralSnapshotExtractionException extends CorallineException {
  /// Creates a [CoralSnapshotExtractionException] describing an invalid extraction attempt.
  ///
  /// * [state]: A human-readable description of the invalid snapshot state (e.g., `'Empty'` or `'Damaged'`).
  /// * [details]: Diagnostic context describing the snapshot instance.
  /// * [error]: The underlying error cause when extracting from a `damaged` snapshot.
  /// * [stackTrace]: The stack trace associated with [error], if available.
  const CoralSnapshotExtractionException(
    this.state,
    this.details, {
    this.error,
    this.stackTrace,
  });

  /// The name of the invalid snapshot state from which extraction was attempted.
  final String state;

  /// Diagnostic context describing the snapshot instance.
  final String details;

  /// The original pipeline error cause if the snapshot was in a `damaged` state.
  final Object? error;

  /// The original stack trace if the snapshot was in a `damaged` state.
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
      buffer.writeln('[Coralline:Error] ORIGINAL PIPELINE ERROR CAUSE:');
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

/// Thrown when attempting to query state metadata incompatible with the current snapshot state.
///
/// Fails when inspecting [CorallineSnapshot.error] or [CorallineSnapshot.stackTrace]
/// from a snapshot state where it does not exist (e.g., querying error on a valid or empty snapshot).
class CoralSnapshotStateException extends CorallineException {
  /// Creates a [CoralSnapshotStateException] for an incompatible metadata query.
  ///
  /// * [state]: A human-readable description of the current snapshot state.
  /// * [details]: Diagnostic context describing the invalid metadata access.
  const CoralSnapshotStateException(this.state, this.details);

  /// The name of the snapshot state on which the incompatible query occurred.
  final String state;

  /// Diagnostic context describing the invalid metadata access.
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

/// Thrown when a reentrant call to `_pushDirty` is detected during active notification.
///
/// This is a programmatic error indicating a cyclic update or structural bug.
class CoralNodeReentrancyError extends StateError {
  /// Creates a [CoralNodeReentrancyError] with an optional diagnostic [message].
  ///
  /// * [message]: Details describing the reentrant notification violation.
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

/// Thrown when a topological error is detected during graph construction or attachment.
///
/// Typically occurs in debug mode when a [CorallineTerminalIntentAware] computation
/// is placed upstream of a [CoralBroadcaster], which acts as an intent firewall.
class CorallineTopologyError extends StateError {
  /// Creates a [CorallineTopologyError] with an optional diagnostic [message].
  ///
  /// * [message]: Details describing the topological violation.
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

/// Thrown when a snapshot or data query is executed on a dormant or deactivated [CoralBroadcaster.coral] branch node.
///
/// This is a fail-fast lifecycle contract violation specific to broadcaster branch lines.
class CoralBroadcasterLineDormantAccessError extends StateError {
  /// Creates a [CoralBroadcasterLineDormantAccessError] for the dormant branch [node].
  ///
  /// * [node]: The dormant branch [CoralNode] that was queried while not running.
  /// * [details]: An optional message describing the failed access.
  CoralBroadcasterLineDormantAccessError(this.node, [String? details])
      : super(details ?? 'snapshot accessed on a dormant broadcaster line node.');

  /// The dormant branch [CoralNode] on which the invalid access was attempted.
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
