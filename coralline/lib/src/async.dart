// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// A convenience extension that bridges Dart's [Future] with the Coralline pipeline.
///
/// This extension allows any [Future] to be integrated as a reactive [Coral] node,
/// allowing asynchronous computations to be lazily computed and managed within
/// the topology graph.
extension FutureCoralExtension<T> on Future<T> {
  /// Converts this [Future] into a reactive [Coral] node.
  ///
  /// While a Dart [Future] begins executing immediately upon creation, attaching
  /// the completion listener (`.then`) and propagating its result into the reactive
  /// graph is deferred until the returned [Coral] node is activated. Until the
  /// [Future] completes after activation, the returned node remains in the `empty`
  /// state (`isEmpty == true`).
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that starts in the `empty` state and updates when this [Future] completes.
  /// * On success, the node transitions to a `valid` state carrying the resolved value of the [Future].
  /// * On error, the node transitions into a `damaged` state, capturing the thrown error ([Object]) and [StackTrace].
  ///
  /// ## Examples
  ///
  /// Basic usage:
  /// ```dart
  /// final myFuture = Future.value(42);
  /// final coral = myFuture.toCoral();
  /// // The completion listener has NOT been attached yet (coral.isEmpty == true).
  ///
  /// final terminal = coral.toTerminal(() {});
  /// terminal.activate(); // Now the Future completion is observed.
  /// ```
  ///
  /// Chaining asynchronous resources in a reactive pipeline:
  /// ```dart
  /// class AsyncSession {
  ///   Future<String> fetchChunk(int length) async => 'chunk($length)';
  ///   Future<void> close() async {}
  /// }
  ///
  /// // Asynchronously open a session, resolve the Future into a session handle,
  /// // and then asynchronously read a chunk of data within a reactive pipeline.
  /// final sessionFutureCoral = Coral.resource(
  ///   create: () => Future.value(AsyncSession()),
  ///   dispose: (sessionFuture) => sessionFuture.then((s) => s.close()),
  /// );
  ///
  /// // The resulting contentCoral has type Coral<String>,
  /// // cleanly abstracting away all intermediate Futures.
  /// final Coral<String> contentCoral = sessionFutureCoral
  ///   // Cascade 1: Convert the Future<AsyncSession> into a reactive Coral
  ///   .cascade((sessionFuture) => sessionFuture.toCoral())
  ///   // Cascade 2: Read from the resolved session, converting the new Future into a Coral
  ///   .cascade((session) => session.fetchChunk(1024).toCoral());
  /// ```
  Coral<T> toCoral() => _DeLorean(this).coral;
}

/// A convenience extension that groups multiple [Future]s into a lifecycle-managed [Trunk].
extension FutureCollectionTrunkExtension<T> on Iterable<Future<T>> {
  /// Converts this collection of [Future]s into a unified [Trunk] of [Coral]s.
  ///
  /// This groups multiple concurrent asynchronous tasks into a single
  /// lifecycle-managed topological bundle. Each child [Coral] starts in the
  /// `empty` state until its corresponding [Future] completes after activation.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] containing [Coral] nodes created from each [Future] in this collection.
  ///
  /// ## Examples
  /// ```dart
  /// final futures = [Future.value(10), Future.value(20)];
  /// final trunk = futures.toTrunk();
  /// final sumCoral = trunk.combine((values) => values.reduce((a, b) => a + b));
  /// ```
  Trunk<T> toTrunk() => Trunk.of(map((future) => _DeLorean(future).coral));
}

/// A convenience extension that bridges Dart's [Stream] with the Coralline pipeline.
///
/// This extension enables any [Stream] to be converted into a reactive [Coral] node,
/// integrating event streams into the declarative topology of Coralline with lazy
/// subscription management.
extension StreamCoralExtension<T> on Stream<T> {
  /// Converts this [Stream] into a reactive [Coral] node.
  ///
  /// Subscription to the [Stream] is deferred until the returned [Coral] node
  /// is activated, is automatically paused and resumed with the node's lifecycle,
  /// and is cancelled when the node is deactivated. Before the first event is
  /// emitted, the returned [Coral] node remains in the `empty` state (`isEmpty == true`).
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is `true`.
  ///
  /// **Requires:**
  /// * If [equals] is provided, [distinct] must be `true`.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that starts in the `empty` state and reflects the events of this [Stream].
  /// * Automatically listens to the [Stream] on activation, pauses/resumes with lifecycle transitions, and cancels the subscription on deactivation.
  ///
  /// ## Examples
  ///
  /// Basic usage:
  /// ```dart
  /// final myStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
  /// final coral = myStream.toCoral(distinct: true);
  ///
  /// final terminal = coral.toTerminal(() {
  ///   if (coral.isValid) {
  ///     print('Tick: ${coral.data}');
  ///   }
  /// });
  /// terminal.activate(); // Starts listening to the stream
  ///
  /// // Later...
  /// terminal.deactivate(); // Automatically cancels the stream subscription
  /// ```
  ///
  /// Cascading a managed client resource into a reactive stream:
  /// ```dart
  /// class EventClient {
  ///   Future<Stream<String>> connect(Uri uri) async => Stream.value('connected:$uri');
  ///   void close() {}
  /// }
  ///
  /// final clientCoral = Coral.resource(
  ///   create: () => EventClient(),
  ///   dispose: (client) => client.close(),
  /// );
  ///
  /// final streamCoral = clientCoral.cascade((client) {
  ///   final responseFuture = client.connect(Uri.parse('https://api.example.com/stream'));
  ///   return responseFuture.toCoral().cascade(
  ///     (eventStream) => eventStream.toCoral(),
  ///   );
  /// });
  /// ```
  Coral<T> toCoral({
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  }) =>
      _StreamCoralPipe(
        this,
        distinct: distinct,
        equals: equals,
        cancelOnError: cancelOnError,
      ).coral;
}

/// A convenience extension that bridges [StreamController] with the Coralline pipeline.
extension StreamControllerCoralExtension<T> on StreamController<T> {
  /// Converts this [StreamController]'s stream into a reactive [Coral] node.
  ///
  /// Subscription to the underlying stream is deferred until the returned [Coral] node
  /// is activated, and is automatically cancelled when the node is deactivated.
  /// Before the first event is emitted, the returned node remains in the `empty` state.
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is `true`.
  ///
  /// **Requires:**
  /// * If [equals] is provided, [distinct] must be `true`.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that reflects the events sent to this [StreamController].
  /// * Automatically listens to the stream on activation and cancels the subscription on deactivation.
  ///
  /// ## Examples
  /// ```dart
  /// final controller = StreamController<int>();
  /// final coral = controller.toCoral();
  ///
  /// final terminal = coral.toTerminal(() {});
  /// terminal.activate(); // Starts listening to the stream
  ///
  /// controller.add(42); // Emitted through the coral
  /// ```
  Coral<T> toCoral({
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  }) =>
      stream.toCoral(
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
      );
}

/// A convenience extension that groups multiple [Stream]s into a lifecycle-managed [Trunk].
extension StreamCollectionTrunkExtension<T> on Iterable<Stream<T>> {
  /// Converts this collection of [Stream]s into a unified [Trunk] of [Coral]s.
  ///
  /// This bundles multiple distinct event streams into a single topology node,
  /// automatically managing the lazy subscriptions and cleanup of every stream
  /// simultaneously based on the [Trunk]'s lifecycle. Each child [Coral] starts
  /// in the `empty` state until its stream emits its first event.
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is `true`.
  ///
  /// **Requires:**
  /// * If [equals] is provided, [distinct] must be `true`.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] containing [Coral] nodes created from each [Stream] in this collection.
  ///
  /// ## Examples
  /// ```dart
  /// final streams = [Stream.value('a'), Stream.value('b')];
  /// final trunk = streams.toTrunk();
  /// final joinedCoral = trunk.combine((items) => items.join(','));
  /// ```
  Trunk<T> toTrunk({
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  }) =>
      Trunk<T>.of(map((stream) => _StreamCoralPipe(
            stream,
            cancelOnError: cancelOnError,
            distinct: distinct,
            equals: equals,
          ).coral));
}
