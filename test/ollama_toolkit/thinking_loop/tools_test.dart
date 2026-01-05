import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/thinking_loop/tools.dart';

void main() {
  group('CalculatorTool', () {
    late CalculatorTool tool;

    setUp(() {
      tool = CalculatorTool();
    });

    test('has correct metadata', () {
      expect(tool.name, 'calculator');
      expect(tool.description, isNotEmpty);
      expect(tool.parameters['type'], 'object');
      expect(tool.parameters['properties'], isNotEmpty);
    });

    test('evaluates addition', () async {
      final result = await tool.execute({'expression': '2 + 3'});
      expect(result, '5.0');
    });

    test('evaluates subtraction', () async {
      final result = await tool.execute({'expression': '10 - 3'});
      expect(result, '7.0');
    });

    test('evaluates multiplication', () async {
      final result = await tool.execute({'expression': '4 * 5'});
      expect(result, '20.0');
    });

    test('evaluates division', () async {
      final result = await tool.execute({'expression': '20 / 4'});
      expect(result, '5.0');
    });

    test('evaluates complex expression', () async {
      final result = await tool.execute({'expression': '2 + 3 * 4'});
      expect(result, '14.0'); // 3*4=12, 2+12=14
    });

    test('handles expressions without spaces', () async {
      final result = await tool.execute({'expression': '10+5'});
      expect(result, '15.0');
    });

    test('handles negative results', () async {
      final result = await tool.execute({'expression': '5 - 10'});
      expect(result, '-5.0');
    });

    test('returns error for invalid expression', () async {
      final result = await tool.execute({'expression': 'invalid'});
      expect(result, contains('Error'));
    });

    test('converts to tool definition', () {
      final definition = tool.toDefinition();

      expect(definition['type'], 'function');
      expect(definition['function']['name'], 'calculator');
      expect(definition['function']['description'], isNotEmpty);
      expect(definition['function']['parameters'], isNotEmpty);
    });
  });

  group('CurrentTimeTool', () {
    late CurrentTimeTool tool;

    setUp(() {
      tool = CurrentTimeTool();
    });

    test('has correct metadata', () {
      expect(tool.name, 'current_time');
      expect(tool.description, isNotEmpty);
      expect(tool.parameters['type'], 'object');
    });

    test('returns ISO 8601 timestamp', () async {
      final result = await tool.execute({});

      expect(result, isNotEmpty);
      // Check if it's a valid ISO 8601 string
      expect(() => DateTime.parse(result), returnsNormally);
    });

    test('returns current time', () async {
      final before = DateTime.now();
      final result = await tool.execute({});
      final after = DateTime.now();

      final timestamp = DateTime.parse(result);
      expect(timestamp.isAfter(before.subtract(Duration(seconds: 1))), true);
      expect(timestamp.isBefore(after.add(Duration(seconds: 1))), true);
    });

    test('converts to tool definition', () {
      final definition = tool.toDefinition();

      expect(definition['type'], 'function');
      expect(definition['function']['name'], 'current_time');
    });
  });

  group('Tool abstract class', () {
    test('toString returns tool name', () {
      final tool = CalculatorTool();
      expect(tool.toString(), 'Tool(calculator)');
    });
  });
}
