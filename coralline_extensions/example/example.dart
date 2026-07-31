import 'package:coralline/coralline.dart';
import 'package:coralline_extensions/coralline_extensions.dart';

void main() {
  // 1. Create a reactive controller holding a collection of numbers
  final numbersController = CoralController<List<double>>([10.0, 20.0, 30.0]);

  // 2. Use coralline_extensions to calculate reactive sum and average
  final sumCoral = numbersController.coral.elements.sum;
  final avgCoral = numbersController.coral.elements.average;

  // 3. Attach terminals to listen and pull data
  final sumTerminal = sumCoral.toTerminal(() {});
  final avgTerminal = avgCoral.toTerminal(() {});

  sumTerminal.activate();
  avgTerminal.activate();

  print('Sum: ${sumTerminal.data}'); // 60.0
  print('Average: ${avgTerminal.data}'); // 20.0

  // 4. Update collection reactively
  numbersController.set([5.0, 15.0, 25.0, 35.0]);

  print('Updated Sum: ${sumTerminal.data}'); // 80.0
  print('Updated Average: ${avgTerminal.data}'); // 20.0

  // Cleanup
  sumTerminal.deactivate();
  avgTerminal.deactivate();
}
