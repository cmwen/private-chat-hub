import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/opencode_api_client.dart';

void main() {
  group('OpenCodeApiClient.buildModelSelection', () {
    test('splits provider/model IDs', () {
      final payload = OpenCodeApiClient.buildModelSelection('openai/gpt-4o');

      expect(payload, {'providerID': 'openai', 'modelID': 'gpt-4o'});
    });

    test('keeps nested model path after first slash', () {
      final payload = OpenCodeApiClient.buildModelSelection(
        'github-copilot/models/gpt-4.1',
      );

      expect(payload, {
        'providerID': 'github-copilot',
        'modelID': 'models/gpt-4.1',
      });
    });

    test('falls back to modelID when provider is missing', () {
      final payload = OpenCodeApiClient.buildModelSelection('gpt-4o');

      expect(payload, {'modelID': 'gpt-4o'});
    });

    test('falls back to modelID for malformed provider model IDs', () {
      final leadingSlash = OpenCodeApiClient.buildModelSelection('/gpt-4o');
      final trailingSlash = OpenCodeApiClient.buildModelSelection('openai/');

      expect(leadingSlash, {'modelID': '/gpt-4o'});
      expect(trailingSlash, {'modelID': 'openai/'});
    });
  });
}
