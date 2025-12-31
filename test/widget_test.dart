// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/main.dart';

void main() {
  testWidgets('Chat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify chat screen loads
    expect(find.text('Private Chat'), findsOneWidget);

    // Verify initial messages are loaded
    expect(find.text('Hey! How are you?'), findsOneWidget);
    expect(find.text('I\'m doing great! Thanks for asking.'), findsOneWidget);

    // Verify message input field exists
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Send message test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Find the text field and enter text
    await tester.enterText(find.byType(TextField), 'Hello, this is a test!');
    await tester.pump();

    // Find and tap the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();

    // Verify the message appears in the chat
    expect(find.text('Hello, this is a test!'), findsOneWidget);
  });
}
