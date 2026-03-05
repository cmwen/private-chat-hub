const Set<String> githubCopilotProviderIds = {
  'copilot',
  'github-copilot-models',
  'github-copilot',
};

bool isGitHubCopilotProviderId(String? providerId) {
  if (providerId == null) return false;
  return githubCopilotProviderIds.contains(providerId.toLowerCase());
}

List<String> enhanceGitHubCopilotCapabilities(List<String> capabilities) {
  final updated = List<String>.from(capabilities);
  void addIfMissing(String value) {
    if (!updated.contains(value)) {
      updated.add(value);
    }
  }

  addIfMissing('tools');
  addIfMissing('vision');
  return updated;
}
