import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/storage_service.dart';
import 'package:expense_tracker/services/app_state.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('Expense tracker app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final appState = AppState(storage);
    await appState.initialize();

    await tester.pumpWidget(ExpenseTrackerApp(appState: appState));
    await tester.pump();

    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
  });
}
