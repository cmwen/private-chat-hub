# Multi-Server Settings UX Review

Date: 2026-03-08

## Current Product Reality

- Ollama already supports multi-profile management with add, delete, and default selection in Settings.
- LM Studio and OpenCode currently expose only a single editable connection card in Settings.
- Model selection is still stored globally by model ID rather than by connection profile.
- OpenCode is conceptually distinct from self-hosted providers, but users still need the same connection-management affordances.

Relevant implementation references:

- Ollama multi-connection list in [lib/screens/settings_screen.dart](../lib/screens/settings_screen.dart#L519)
- Single-card LM Studio settings in [lib/screens/settings_screen.dart](../lib/screens/settings_screen.dart#L2103)
- Single-card OpenCode settings in [lib/screens/settings_screen.dart](../lib/screens/settings_screen.dart#L1839)
- Global selected model storage in [lib/services/connection_service.dart](../lib/services/connection_service.dart#L11)
- Model fallback when selected model no longer exists in [lib/screens/models_screen.dart](../lib/screens/models_screen.dart#L128)
- Current unreachable-state chat copy in [lib/services/chat_service.dart](../lib/services/chat_service.dart#L989)
- Current unreachable-state chat copy in [lib/services/chat_service.dart](../lib/services/chat_service.dart#L1122)

## Recommendation Summary

LM Studio and OpenCode should adopt the same multi-server management pattern as Ollama: a list of saved servers, one default server per provider, explicit add/edit/delete actions, and an active-status indicator on each saved item. The list pattern should be consistent across all providers, but OpenCode should remain visually separated because it represents a gateway to hosted providers rather than a self-hosted runtime.

The key UX change is to separate three concepts that are currently blurred together:

1. Configured: the app has one or more saved server profiles.
2. Default: the server profile the app will try first for that provider.
3. Reachable now: the saved server responded to a health check recently.

## Settings UX

### 1. Provider Sections

Keep three sections in Settings:

- Self-Hosted Servers
- OpenCode
- On-Device Models

Within Self-Hosted Servers, show two parallel subsections:

- Ollama
- LM Studio

OpenCode should stay in its own top-level section, not merged under Self-Hosted Servers.

### 2. List Pattern For All Network Providers

For Ollama, LM Studio, and OpenCode, use the same saved-server list pattern:

- Section header with provider name and short description.
- Empty state card when no servers are configured.
- List of saved server cards when at least one exists.
- Persistent Add Server action below the list.

Each saved server card should include:

- Server name
- Endpoint line
- Status chip
- Default badge when applicable
- Optional last successful connection timestamp
- Overflow menu with Test Connection, Edit, Set as Default, and Delete

Preferred status chips:

- Default
- Reachable
- Unreachable
- Needs attention

Do not overload the default badge to imply health. A default server can still be offline.

### 3. Add And Edit Flow

Use the same add/edit dialog pattern for all three providers.

Dialog structure:

- Name
- Host
- Port
- HTTPS toggle
- Provider-specific auth fields
- Test Connection secondary action
- Save primary action
- Optional Save and Make Default action when editing or adding a non-first profile

Recommended default names:

- Ollama Server
- LM Studio Server
- OpenCode Server

If network discovery remains Ollama-only, keep that as a provider-specific enhancement, not a different information architecture.

## Default And Active Server Selection

### 1. Default Selection

Use default server as the only persistent provider-level selection in Settings.

Rules:

- The first saved server becomes default automatically.
- Setting another server as default demotes the previous one.
- Deleting the default promotes the next remaining server and shows a snackbar.

Recommended copy for the snackbar:

- Default server deleted. Another saved server is now the default.

### 2. Active Server

Do not ask users to manage a separate manual active server concept in Settings unless the app truly supports runtime switching independent of default. For now, the active server should be presented as derived state:

- Active now = the default server currently bound by the app for that provider.

Presentation on the card:

- Default badge
- Secondary status line: Currently in use

Only show Currently in use when the screen is reflecting the live bound connection, not just saved preference.

### 3. Model-Screen Consistency

Because the app stores a single global selected model ID today, server switching can invalidate that selection across LM Studio and OpenCode. The UX should acknowledge this explicitly until the data model is upgraded.

Recommended near-term behavior:

- When the default server changes for LM Studio or OpenCode, immediately revalidate model availability.
- If the selected model is missing on the new default server, preserve the conversation model if possible, but replace the global picker selection with the first available model from that provider and inform the user.

Recommended snackbar copy:

- The previously selected model is not available on this server. Switched to the first available model.

Longer-term product fix:

- Store model selection per provider connection profile, not only as a global model ID.

## Empty States And Error Copy

The app must distinguish between:

- no saved server
- saved server exists but is offline or unreachable
- selected server was deleted from configuration
- selected model no longer exists on the current server

### 1. No Server Configured

Use when zero saved profiles exist for that provider.

LM Studio empty state:

- Title: No LM Studio servers
- Body: Add an LM Studio server to browse and use its local models.
- Primary action: Add Server

OpenCode empty state:

- Title: No OpenCode servers
- Body: Add an OpenCode server to access hosted providers through your gateway.
- Primary action: Add Server

Ollama empty state refinement:

- Title: No Ollama servers
- Body: Add an Ollama server to browse and run your self-hosted models.
- Primary action: Add Server

### 2. Saved Server Unreachable Or Offline

Use when a saved default server exists but the health check fails.

LM Studio unreachable state:

- Title: LM Studio server unavailable
- Body: Saved server "{serverName}" is not responding right now. Check that LM Studio is running and reachable at {host}:{port}.
- Primary action: Retry
- Secondary action: Edit Server

OpenCode unreachable state:

- Title: OpenCode server unavailable
- Body: Saved server "{serverName}" is not responding right now. Check the server address, credentials, and network connection.
- Primary action: Retry
- Secondary action: Edit Server

Ollama unreachable state:

- Title: Ollama server unavailable
- Body: Saved server "{serverName}" is not responding right now. Check that Ollama is running and reachable at {host}:{port}.
- Primary action: Retry
- Secondary action: Edit Server

Use unavailable instead of deleted here. The configuration still exists.

### 3. Server Was Deleted Or No Longer Configured

Use when the app has a stale pointer to a formerly selected/default server, or when a conversation references a provider model but the provider now has zero saved servers.

LM Studio deleted state:

- Title: LM Studio server removed
- Body: The LM Studio server previously used by this app is no longer saved. Choose another server or add a new one.
- Primary action: Choose Server
- Secondary action: Add Server

OpenCode deleted state:

- Title: OpenCode server removed
- Body: The OpenCode server previously used by this app is no longer saved. Choose another server or add a new one.
- Primary action: Choose Server
- Secondary action: Add Server

Ollama deleted state:

- Title: Ollama server removed
- Body: The Ollama server previously used by this app is no longer saved. Choose another server or add a new one.
- Primary action: Choose Server
- Secondary action: Add Server

This state should not tell the user to check whether the server is running. The configuration problem is different from availability.

### 4. Model Missing On Current Server

Use when a provider is configured and reachable, but the selected model ID is absent on the active default server.

- Title: Model not available on this server
- Body: "{modelName}" is not available on "{serverName}". Choose another model or switch servers.
- Primary action: Choose Model
- Secondary action: Switch Server

### 5. Inline Banner Copy For Chat Attempts

When user tries to send with a provider model and no server is configured:

- OpenCode is not set up. Add an OpenCode server in Settings to use this model.
- LM Studio is not set up. Add an LM Studio server in Settings to use this model.
- Ollama is not set up. Add an Ollama server in Settings to use this model.

When user tries to send with a configured but unreachable server:

- OpenCode server "{serverName}" is unavailable right now. Retry, edit the server, or switch providers.
- LM Studio server "{serverName}" is unavailable right now. Retry, edit the server, or switch providers.
- Ollama server "{serverName}" is unavailable right now. Retry, edit the server, or switch providers.

## OpenCode Visual Treatment

OpenCode should remain visually separate while getting connection-management parity.

Reasoning:

- Ollama and LM Studio are both self-hosted model runtimes and belong together under Self-Hosted Servers.
- OpenCode is a gateway to hosted providers and carries different trust, billing, and credential expectations.
- Users still need the same operational controls: add, edit, delete, test, default.

Recommended treatment:

- Keep OpenCode in its own section.
- Use the same card/list behavior as Ollama and LM Studio.
- Give OpenCode distinct iconography and helper text.
- Avoid changing the interaction model just to preserve conceptual separation.

In short: visual separation, interaction parity.

## Interaction Notes

Recommended provider card statuses:

- Default + Reachable
- Default + Unreachable
- Reachable
- Unreachable

Recommended destructive-delete confirmation:

- Title: Delete server?
- Body: Remove "{serverName}" from saved servers? This does not delete any models from the server itself.
- Confirm: Delete Server
- Cancel: Cancel

Recommended default-change confirmation is not necessary. Use immediate action plus snackbar feedback.

## Product Risks To Watch

- A global selected model ID is increasingly fragile once one provider can point to many endpoints.
- Users will assume default means healthy unless health is shown separately.
- Disconnect is the wrong mental model once multiple saved servers exist; use Delete Server for persistence and Set as Default for preference.
- If the app silently falls back to a different model after server change, users may not notice the change in capability or privacy boundary.

## Recommended Priority Order

1. Give LM Studio and OpenCode the same saved-server list pattern as Ollama.
2. Add distinct empty, unreachable, removed, and missing-model states.
3. Separate default from health in all provider cards.
4. Revalidate selected model on server change and notify the user when fallback happens.
5. Move from global model selection to per-provider or per-connection selection in a later pass.