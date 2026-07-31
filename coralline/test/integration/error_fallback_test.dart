// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:test/test.dart';
import 'package:coralline/coralline.dart';

void main() {
  group('4. Error Isolation & Fallback (Damaged State)', () {
    test('Runtime Lazy Computation Error yields Damaged Snapshot safely', () {
      final source = CoralController<int>(10);

      final cascaded = source.coral.cascade((data) {
        if (data == 10) throw Exception('Intentional failure');
        return Coral.data(data * 2);
      });

      final terminal = cascaded.toTerminal(() {});

      terminal.activate();

      // Pulling data should not crash the app, but return a damaged snapshot
      final snapshot = terminal.snapshot;
      expect(snapshot.isDamaged, true, reason: 'Snapshot should capture the exception safely');
      expect(snapshot.error, isNotNull);

      // Bypass Fail-Fast to check fallback
      expect(snapshot.dataOrNull, isNull, reason: 'dataOrNull safely returns null for damaged state');
      expect(snapshot.dataOrElse(() => -1), -1);

      terminal.deactivate();
    });

    test('Trunk Merge Error evacuation', () {
      final validSource = CoralController<int>(1);
      final damagedSource = CoralController<int>(2)..setError(Exception('Trunk failure'));

      final merged = [validSource.coral, damagedSource.coral].toTrunk().combine();
      final terminal = merged.toTerminal(() {});

      terminal.activate();

      final snapshot = terminal.snapshot;
      expect(snapshot.isDamaged, true, reason: 'If any line is damaged, the combined snapshot is damaged');

      terminal.deactivate();
    });

    test('CoralSnapshotExtractionException chains original error and stacktrace', () {
      final error = Exception('Original computation error');
      final damagedCoral = Coral<int>.damaged(error, StackTrace.current);

      try {
        damagedCoral.data;
        fail('Should throw CoralSnapshotExtractionException');
      } on CoralSnapshotExtractionException catch (e) {
        expect(e.error, error);
        expect(e.toString(), contains('🚨 ORIGINAL PIPELINE ERROR CAUSE:'));
        expect(e.toString(), contains('Original computation error'));
      }

      final damagedTrunk = Trunk<int>.damaged(error, StackTrace.current);
      try {
        damagedTrunk.lines;
        fail('Should throw CoralSnapshotExtractionException');
      } on CoralSnapshotExtractionException catch (e) {
        expect(e.error, error);
        expect(e.toString(), contains('🚨 ORIGINAL PIPELINE ERROR CAUSE:'));
        expect(e.toString(), contains('Original computation error'));
      }
    });
  });
}
