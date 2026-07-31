// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

final class TestTerminalIntent extends CorallineTerminalIntent {
  Object? caughtError;
  StackTrace? caughtStackTrace;

  @override
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    caughtError = error;
    caughtStackTrace = stackTrace;
  }
}

void main() {
  group('terminal.dart Constructors & Public API Comprehensive Tests', () {
    group('CoralTerminal Constructors & Inbound/Intent Properties', () {
      test('CoralTerminal standard constructor sets default null intent and matches inbound', () {
        final coral = Coral.data('test_value');
        final terminal = CoralTerminal(coral, onDirty: () {});

        expect(terminal.inbound, same(coral));
        expect(terminal.intent, isNull);
      });

      test('CoralTerminal.withIntent sets custom intent', () {
        final coral = Coral.data('test_value');
        final customIntent = TestTerminalIntent();
        final terminal = CoralTerminal.withIntent(coral, intent: customIntent, onDirty: () {});

        expect(terminal.inbound, same(coral));
        expect(terminal.intent, same(customIntent));
      });

      test('CoralTerminal delegates snapshot properties directly', () {
        final coral = Coral.data(123);
        final terminal = CoralTerminal(coral, onDirty: () {});

        terminal.activate();

        expect(terminal.snapshot, isA<CoralSnapshot<int>>());
        expect(terminal.isValid, isTrue);
        expect(terminal.isEmpty, isFalse);
        expect(terminal.isDamaged, isFalse);
        expect(terminal.data, 123);
        expect(terminal.dataOrNull, 123);
        expect(terminal.dataOrElse(() => 999), 123);

        terminal.deactivate();
      });
    });

    group('TrunkTerminal Constructors & Inbound/Intent Properties', () {
      test('TrunkTerminal standard constructor sets default null intent and matches inbound', () {
        final trunk = [Coral.data('a'), Coral.data('b')].toTrunk();
        final terminal = TrunkTerminal(trunk, onDirty: () {});

        expect(terminal.inbound, same(trunk));
        expect(terminal.intent, isNull);
      });

      test('TrunkTerminal.withIntent sets custom intent', () {
        final trunk = [Coral.data('a')].toTrunk();
        final customIntent = TestTerminalIntent();
        final terminal = TrunkTerminal.withIntent(trunk, intent: customIntent, onDirty: () {});

        expect(terminal.inbound, same(trunk));
        expect(terminal.intent, same(customIntent));
      });

      test('TrunkTerminal delegates snapshot properties directly', () {
        final trunk = [Coral.data(10), Coral.data(20)].toTrunk();
        final terminal = TrunkTerminal(trunk, onDirty: () {});

        terminal.activate();

        expect(terminal.snapshot, isA<TrunkSnapshot<int>>());
        expect(terminal.isValid, isTrue);
        expect(terminal.isEmpty, isFalse);
        expect(terminal.isDamaged, isFalse);
        expect(terminal.lines.map((c) => c.data).toList(), [10, 20]);
        expect(terminal.linesOrNull?.map((c) => c.data).toList(), [10, 20]);
        expect(terminal.linesOrEmpty.map((c) => c.data).toList(), [10, 20]);

        terminal.deactivate();
      });
    });

    group('Terminal Lifecycle Methods & Status Getters (activate, pause, resume, deactivate)', () {
      test('Complete lifecycle state machine and idempotency checks', () {
        final controller = CoralController<int>(1);
        final terminal = controller.coral.toTerminal(() {});

        // Initial state before activation
        expect(terminal.isActivated, isFalse);
        expect(terminal.isRunning, isFalse);
        expect(terminal.isPaused, isFalse);
        expect(terminal.isDeactivated, isTrue);

        // 1. Activate
        terminal.activate();
        expect(terminal.isActivated, isTrue);
        expect(terminal.isRunning, isTrue);
        expect(terminal.isPaused, isFalse);
        expect(terminal.isDeactivated, isFalse);

        // Idempotent activate()
        terminal.activate();
        expect(terminal.isActivated, isTrue);
        expect(terminal.isRunning, isTrue);

        // 2. Pause
        terminal.pause();
        expect(terminal.isActivated, isTrue);
        expect(terminal.isRunning, isFalse);
        expect(terminal.isPaused, isTrue);
        expect(terminal.isDeactivated, isFalse);

        // Idempotent pause()
        terminal.pause();
        expect(terminal.isPaused, isTrue);

        // 3. Resume
        terminal.resume();
        expect(terminal.isActivated, isTrue);
        expect(terminal.isRunning, isTrue);
        expect(terminal.isPaused, isFalse);
        expect(terminal.isDeactivated, isFalse);

        // Idempotent resume()
        terminal.resume();
        expect(terminal.isRunning, isTrue);

        // 4. Deactivate
        terminal.deactivate();
        expect(terminal.isActivated, isFalse);
        expect(terminal.isRunning, isFalse);
        expect(terminal.isPaused, isFalse);
        expect(terminal.isDeactivated, isTrue);

        // Idempotent deactivate()
        terminal.deactivate();
        expect(terminal.isDeactivated, isTrue);
      });
    });

    group('CorallineTerminalIntent Error Interception Tests', () {
      test('Custom intent receives handleUncaughtError callback', () {
        final intent = TestTerminalIntent();
        final error = FormatException('Intent Error Test');
        final stackTrace = StackTrace.current;

        intent.handleUncaughtError(error, stackTrace);

        expect(intent.caughtError, same(error));
        expect(intent.caughtStackTrace, same(stackTrace));
      });
    });
  });
}
