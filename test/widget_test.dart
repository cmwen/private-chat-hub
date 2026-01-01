// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/screens/chat_screen.dart';

void main() {
  testWidgets('Chat screen smoke test', (WidgetTester tester) async {
    // Build the chat screen in demo mode (no services)
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));

    // Verify chat screen loads with demo message
    expect(find.text('Chat'), findsOneWidget);

    // Verify demo mode indicator
    expect(find.text('Demo Mode'), findsOneWidget);

    // Verify message input field exists
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Send message in demo mode', (WidgetTester tester) async {
    // Build the chat screen in demo mode
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));

    // Find the text field and enter text
    await tester.enterText(find.byType(TextField), 'Hello!');
    await tester.pump();

    // Find and tap the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();

    // Verify the user message appears in the chat
    expect(find.text('Hello!'), findsOneWidget);

    // Wait for demo response
    await tester.pump(const Duration(milliseconds: 600));

    // Verify demo response appears
    expect(find.textContaining('Great to hear from you'), findsOneWidget);
  });
}
