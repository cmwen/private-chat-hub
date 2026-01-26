import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/main.dart';
import 'package:private_chat_hub/data/datasources/local/database_helper.dart';
import 'package:private_chat_hub/data/repositories/settings_repository.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    final dbHelper = DatabaseHelper();
    final settingsRepo = await SettingsRepository.create();

    await tester.pumpWidget(
      PrivateChatHub(dbHelper: dbHelper, settingsRepo: settingsRepo),
    );

    expect(find.text('Private Chat Hub'), findsOneWidget);
  });
}
