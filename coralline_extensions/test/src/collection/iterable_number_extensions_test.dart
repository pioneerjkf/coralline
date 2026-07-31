import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/collection/iterable_number_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('NumericCoralElementsExtension', () {
    test('sum and average compute numeric elements reactively', () {
      final controller =
          CoralController<List<double>>([1.5, 2.5, 4.0], broadcast: true);

      final sumCoral = controller.coral.elements.sum;
      final avgCoral = controller.coral.elements.average;

      final termSum = sumCoral.toTerminal(() {});
      final termAvg = avgCoral.toTerminal(() {});
      termSum.activate();
      termAvg.activate();

      expect(termSum.snapshot.data, 8.0);
      expect(termAvg.snapshot.data, 8.0 / 3);

      controller.set([10.0, 20.0]);
      expect(termSum.snapshot.data, 30.0);
      expect(termAvg.snapshot.data, 15.0);

      controller.set([]);
      expect(termSum.snapshot.data, 0.0);
      expect(termAvg.snapshot.isDamaged, isTrue);
      expect(termAvg.snapshot.error, isA<StateError>());

      termSum.deactivate();
      termAvg.deactivate();
    });
  });
}
