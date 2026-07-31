import 'package:coralline/coralline.dart';

void main() {
  // 1. Create a reactive controller
  final counterController = CoralController<int>(0);

  // 2. Build a lazy computational pipeline
  final doubledCounter = counterController.coral.map((count) => count * 2).distinct();

  // 3. Attach a terminal listener
  final terminal = doubledCounter.toTerminal(() {
    print('Dirty signal received!');
  });

  // 4. Activate terminal (starts lazy lifecycle)
  terminal.activate();

  // 5. Pull data lazily
  print('Initial Value: ${terminal.data}'); // 0

  // 6. Update state upstream
  counterController.set(5);

  // 7. Pull updated data lazily
  print('Updated Value: ${terminal.data}'); // 10

  // Clean up
  terminal.deactivate();
}
