// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// A convenience extension that bridges Dart's [Future] with the Coralline pipeline.
///
/// This extension allows any [Future] to be integrated as a reactive [Coral] node,
/// allowing asynchronous computations to be lazily computed and managed within
/// the topology graph.
extension FutureThatMixesCoral<T> on Future<T> {
  /// Converts this [Future] into a reactive [Coral] node.
  ///
  /// Subscription to the [Future] (`.then`) is deferred until the returned [Coral]
  /// node is activated, avoiding unnecessary execution of asynchronous logic before the
  /// data is actually needed.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that completes when this [Future] completes.
  /// * On success, the node carries the computed value of the [Future].
  /// * On error, the node transitions into a damaged state, propagating the [Exception] and [StackTrace].
  ///
  /// **Example (Basic):**
  /// ```dart
  /// final myFuture = Future.value(42);
  /// final coral = myFuture.toCoral();
  /// // The Future has NOT started propagating data yet.
  ///
  /// final terminal = coral.toTerminal(() {});
  /// terminal.activate(); // Now the Future is actively observed.
  /// ```
  ///
  /// **Example (Advanced Real-World Usage):**
  /// ```dart
  /// // Asynchronously open a file, resolve the Future into a file handle,
  /// // and then asynchronously read a chunk of data, all within a reactive pipeline.
  /// final fileFutureCoral = Coral.resource(
  ///   create: () => File('data.txt').open(mode: FileMode.read),
  ///   dispose: (fileFuture) => fileFuture.then((file) => file.close()),
  /// );
  ///
  /// // The resulting contentCoral has type Coral<Uint8List>,
  /// // cleanly abstracting away all intermediate Futures.
  /// final Coral<Uint8List> contentCoral = fileFutureCoral
  ///   // Cascade 1: Convert the Future<RandomAccessFile> into a reactive Coral
  ///   .cascade((fileFuture) => fileFuture.toCoral())
  ///   // Cascade 2: Read from the resolved file, converting the new Future into a Coral
  ///   .cascade((file) => file.read(1024).toCoral());
  /// ```
  Coral<T> toCoral() => _DeLorean(this).coral;
}

/// A convenience extension that groups multiple [Future]s into a lifecycle-managed [Trunk].
extension FutureCollectionThatMixesTrunk<T> on Iterable<Future<T>> {
  /// Converts this collection of [Future]s into a unified [Trunk] of [Coral]s.
  ///
  /// This is useful for grouping multiple concurrent asynchronous tasks
  /// into a single lifecycle-managed topological bundle.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] containing [Coral] nodes created from each [Future] in this collection.
  Trunk<T> toTrunk() => Trunk.of(map((future) => _DeLorean(future).coral));
}

/// A convenience extension that bridges Dart's [Stream] with the Coralline pipeline.
///
/// This extension enables any [Stream] to be converted into a reactive [Coral] node,
/// integrating event streams into the declarative topology of Coralline with lazy
/// subscription management.
extension StreamThatMixesCoral<T> on Stream<T> {
  /// Converts this [Stream] into a reactive [Coral] node.
  ///
  /// Subscription to the [Stream] is deferred until the returned [Coral] node
  /// is activated, and is automatically cancelled when the node is deactivated,
  /// preventing resource and memory leaks.
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is true.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that reflects the events of this [Stream].
  /// * Automatically listens to the [Stream] on activation and cancels the subscription on deactivation.
  ///
  /// **Example (Basic):**
  /// ```dart
  /// final myStream = Stream.periodic(Duration(seconds: 1), (i) => i);
  /// final coral = myStream.toCoral(distinct: true);
  ///
  /// final terminal = coral.toTerminal(() => setState(() {}));
  /// terminal.activate(); // Starts listening to the stream
  ///
  /// // Later...
  /// terminal.deactivate(); // Automatically cancels the stream subscription!
  /// ```
  ///
  /// **Example (Advanced Real-World Usage):**
  /// ```dart
  /// // Safely manage an HTTP client for a streaming connection
  /// final httpClientCoral = Coral.resource(
  ///   create: () => HttpClient(),
  ///   dispose: (client) => client.close(force: true),
  /// );
  ///
  /// // Fetch the HTTP response asynchronously, then cascade to convert
  /// // the resulting byte Stream into a reactive Coral node.
  /// final streamCoral = httpClientCoral.cascade((client) {
  ///   final responseFuture = client.getUrl(Uri.parse('https://api.example.com/stream'))
  ///       .then((request) => request.close());
  ///
  ///   return responseFuture.toCoral().cascade(
  ///     (responseStream) => responseStream.toCoral(),
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
extension StreamControllerThatMixesCoral<T> on StreamController<T> {
  /// Converts this [StreamController]'s stream into a reactive [Coral] node.
  ///
  /// Subscription to the underlying stream is deferred until the returned [Coral] node
  /// is activated, and is automatically cancelled when the node is deactivated.
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is true.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that reflects the events sent to this [StreamController].
  /// * Automatically listens to the stream on activation and cancels the subscription on deactivation.
  ///
  /// **Example:**
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
extension StreamCollectionThatMixesTrunk<T> on Iterable<Stream<T>> {
  /// Converts this collection of [Stream]s into a unified [Trunk] of [Coral]s.
  ///
  /// This bundles multiple distinct event streams into a single topology node,
  /// automatically managing the lazy subscriptions and cleanup of every stream
  /// simultaneously based on the [Trunk]'s lifecycle.
  ///
  /// * [cancelOnError]: If `true`, the underlying subscription is cancelled immediately if an error occurs.
  /// * [distinct]: If `true`, identical consecutive events are ignored.
  /// * [equals]: A custom equality function to compare the previous and next events when [distinct] is true.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] containing [Coral] nodes created from each [Stream] in this collection.
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
