import 'dart:async';

import 'package:coralline/coralline.dart';
import 'package:test/test.dart';

void main() {
  group('Future.toCoral()', () {
    test('resolves with a value when the Future completes successfully', () async {
      final completer = Completer<int>();
      final coral = completer.future.toCoral();

      // Ensure the initial state is empty
      expect(coral.snapshot.isEmpty, isTrue);

      final terminal = coral.toTerminal(() {});
      terminal.activate();

      completer.complete(42);

      // Wait for the future to finish
      await Future<void>.delayed(Duration.zero);

      expect(terminal.snapshot.isValid, isTrue);
      expect(terminal.data, 42);

      terminal.deactivate();
    });

    test('resolves with an error when the Future completes with an error', () async {
      final completer = Completer<int>();
      final coral = completer.future.toCoral();

      final terminal = coral.toTerminal(() {});
      terminal.activate();

      final exception = Exception('Something went wrong');
      completer.completeError(exception);

      // Wait for the future to finish
      await Future<void>.delayed(Duration.zero);

      expect(terminal.snapshot.isDamaged, isTrue);
      expect(terminal.error, exception);

      terminal.deactivate();
    });

    test('prevents multiple subscriptions to the same Future via _DeLorean._isStarted', () async {
      final completer = Completer<int>();
      final coral = completer.future.toCoral();

      int onDirtyCount = 0;
      final terminal = coral.toTerminal(() {
        onDirtyCount++;
      });

      terminal.activate();
      // Emulate a second activation scenario (DeLorean._isStarted should prevent duplicate .then calls)
      terminal.deactivate();
      terminal.activate();

      completer.complete(100);
      await Future<void>.delayed(Duration.zero);

      expect(terminal.data, 100);
      expect(onDirtyCount, 1); // Should only dirty once upon completion

      terminal.deactivate();
    });
  });

  group('Iterable<Future>.toTrunk()', () {
    test('transforms a list of Futures into a Trunk of Corals', () async {
      final completer1 = Completer<String>();
      final completer2 = Completer<String>();
      final futures = [completer1.future, completer2.future];

      final trunk = futures.toTrunk();
      expect(trunk.lines.length, 2);

      final terminal = trunk.toTerminal(() {});
      terminal.activate();

      completer1.complete('Hello');
      completer2.complete('World');

      await Future<void>.delayed(Duration.zero);

      final dataList = terminal.lines.data.toList();
      expect(dataList, ['Hello', 'World']);

      terminal.deactivate();
    });
  });

  group('Stream.toCoral()', () {
    test('updates Coral data as stream events occur', () async {
      final controller = StreamController<int>();
      final coral = controller.stream.toCoral();

      int onDirtyCount = 0;
      final terminal = coral.toTerminal(() {
        onDirtyCount++;
      });
      terminal.activate();

      expect(terminal.snapshot.isEmpty, isTrue);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(terminal.data, 1);
      expect(onDirtyCount, 1);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(terminal.data, 2);
      expect(onDirtyCount, 2);

      await controller.close();
      terminal.deactivate();
    });

    test('handles distinct correctly', () async {
      final controller = StreamController<int>();
      final coral = controller.stream.toCoral(distinct: true);

      int onDirtyCount = 0;
      late final CoralTerminal<int> terminal;
      terminal = coral.toTerminal(() {
        onDirtyCount++;
        terminal.snapshot;
      });
      terminal.activate();

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      controller.add(1); // Should be ignored
      await Future<void>.delayed(Duration.zero);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(terminal.data, 2);
      expect(onDirtyCount, 2); // Only two dirty events

      await controller.close();
      terminal.deactivate();
    });

    test('handles errors and cancelOnError correctly', () async {
      final controller = StreamController<int>();
      final coral = controller.stream.toCoral(cancelOnError: true);

      final terminal = coral.toTerminal(() {});
      terminal.activate();

      final exception = Exception('Stream error');
      controller.addError(exception);
      await Future<void>.delayed(Duration.zero);

      expect(terminal.snapshot.isDamaged, isTrue);
      expect(terminal.error, exception);

      // Verify subscription is cancelled because cancelOnError is true
      expect(controller.hasListener, isFalse);

      await controller.close();
      terminal.deactivate();
    });

    test('unsubscribes when terminal is deactivated', () async {
      final controller = StreamController<int>();
      final coral = controller.stream.toCoral();

      final terminal = coral.toTerminal(() {});
      terminal.activate();

      expect(controller.hasListener, isTrue);

      terminal.deactivate();

      expect(controller.hasListener, isFalse);

      await controller.close();
    });

    test('pauses and resumes stream subscription when terminal is paused and resumed', () async {
      final controller = StreamController<int>();
      final coral = controller.stream.toCoral();

      int onDirtyCount = 0;
      final terminal = coral.toTerminal(() {
        onDirtyCount++;
      });
      terminal.activate();

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(terminal.data, 1);
      expect(onDirtyCount, 1);

      terminal.pause();
      expect(controller.isPaused, isTrue);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(terminal.data, 1);
      expect(onDirtyCount, 1);

      terminal.resume();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isPaused, isFalse);
      expect(terminal.data, 2);
      expect(onDirtyCount, 2);

      await controller.close();
      terminal.deactivate();
    });
  });

  group('Iterable<Stream>.toTrunk()', () {
    test('transforms a list of Streams into a Trunk of Corals', () async {
      final controller1 = StreamController<String>();
      final controller2 = StreamController<String>();
      final streams = [controller1.stream, controller2.stream];

      final trunk = streams.toTrunk();
      expect(trunk.lines.length, 2);

      final terminal = trunk.toTerminal(() {});
      terminal.activate();

      controller1.add('Hello');
      controller2.add('World');

      await Future<void>.delayed(Duration.zero);

      final dataList = terminal.lines.data.toList();
      expect(dataList, ['Hello', 'World']);

      await controller1.close();
      await controller2.close();
      terminal.deactivate();
    });
  });
}
