# Architecture: LM Studio REST Integration

Date: 2026-03-08
Status: Recommended

## Goal

Add LM Studio as a fourth backend capability without making the app feel like it has a fourth top-level operating mode in Settings.

## Recommendation

Keep LM Studio under the existing remote category rather than adding a new `InferenceMode`.

Introduce a small remote-provider abstraction so Ollama and LM Studio become sibling implementations behind the same remote UX surface:

- `RemoteProviderKind.ollama`
- `RemoteProviderKind.lmStudio`

Use provider-qualified model IDs for all non-on-device models:

- Ollama: `ollama:model-name`
- LM Studio: `lmstudio:model-id`
- OpenCode: keep `opencode:provider/model`
- LiteRT: keep `local:model-id`

This removes the current implicit rule where an unprefixed model means Ollama, and lets chat routing depend on model ID parsing instead of mode-specific fallbacks.

## Concrete shape

### Add

- `lib/models/remote_connection.dart`
  - General remote connection profile with shared fields: `id`, `name`, `host`, `port`, `useHttps`, `isDefault`, `createdAt`, `lastConnectedAt`, `providerKind`
  - Optional provider-specific extras map only if needed later

- `lib/services/remote_connection_service.dart`
  - Stores remote connections for both Ollama and LM Studio
  - Replaces Ollama-only storage assumptions over time
  - Supports filtering by provider kind

- `lib/services/model_id_service.dart`
  - `parse(String modelId) -> ParsedModelId`
  - `isLocal`, `isOpenCode`, `isRemote`, `isOllama`, `isLmStudio`
  - `toDisplayName`, `providerPrefix`, `rawModelId`

- `lib/services/lm_studio_connection_manager.dart`
  - Mirrors `ollama_connection_manager.dart`
  - Holds active LM Studio connection and HTTP client
  - Supports health check and timeout

- `lib/services/lm_studio_api_client.dart`
  - Wraps `/api/v1/models`, `/api/v1/chat`, and optional load/unload endpoints
  - Handles streaming response decoding

- `lib/services/lm_studio_llm_service.dart`
  - Implements `LLMService`
  - Converts LM Studio model metadata into `ModelInfo`
  - Strips `lmstudio:` prefix before API calls

- `lib/models/lm_studio_connection.dart`
  - Only if you want the smallest first step and do not want to generalize remote connection storage yet

## Change

- `lib/services/llm_service.dart`
  - Keep `InferenceMode` as `remote`, `onDevice`, `openCode`
  - Add `ModelSource` or leave source derivation to `model_id_service.dart`

- `lib/services/inference_config_service.dart`
  - Keep current mode enum
  - Add `RemoteProviderKind currentRemoteProvider`
  - Split last-used remote model into:
    - `lastOllamaModel`
    - `lastLmStudioModel`
  - Keep `lastRemoteModel` as compatibility shim during migration if needed

- `lib/services/chat_service.dart`
  - Replace prefix checks that only know `local:` and `opencode:` with `ModelIdService.parse(...)`
  - Route by parsed provider:
    - `local` -> `OnDeviceLLMService`
    - `opencode` -> `OpenCodeLLMService`
    - `ollama` -> `Ollama` path
    - `lmstudio` -> `LMStudioLLMService`
  - Keep `InferenceMode` for default model selection and UI state, not final execution routing

- `lib/services/unified_model_service.dart`
  - Add LM Studio model fetch and merge
  - Cache remote models by provider, not only by `isLocal == false`
  - Recommended cache keys:
    - `cached_remote_models_ollama`
    - `cached_remote_models_lmstudio`
    - or a single structured map keyed by provider

- `lib/screens/settings_screen.dart`
  - Replace separate provider-heavy remote cards with a single `Remote Models` section
  - Inside it:
    - segmented control or dropdown: `Ollama | LM Studio`
    - provider-specific connection card beneath the selector
  - Keep OpenCode separate because it is conceptually cloud gateway, not self-hosted local-network inference

- `lib/screens/models_screen.dart`
  - Replace `Ollama Models` section with `Remote Models`
  - Group models by provider within that section:
    - `Ollama`
    - `LM Studio`
  - Keep OpenCode and On-Device as separate sections
  - Reuse the same card style for Ollama and LM Studio so LM Studio feels like Ollama

## Why not a separate inference mode

Adding `InferenceMode.lmStudio` would leak transport/provider details into the app's top-level mental model.

That would create four modes:

- remote
- on-device
- openCode
- lmStudio

But LM Studio is not a distinct user workflow in the same sense as LiteRT or OpenCode. It is another self-hosted remote server similar to Ollama. Making it a separate mode would:

- clutter Settings
- add more mode-specific persistence branches
- make defaults harder to explain
- encourage more special cases in `chat_service.dart`

Use one remote mode, plus a selected remote provider.

## Routing strategy

Recommended canonical prefixes:

- `local:` for LiteRT
- `opencode:` for OpenCode
- `ollama:` for Ollama
- `lmstudio:` for LM Studio

Then centralize parsing in one place.

Do not keep the current rule that bare model IDs imply Ollama once migration is complete. That rule is convenient today but becomes brittle as soon as two remote REST backends expose overlapping model names.

Compatibility transition:

- continue to treat unprefixed IDs as `ollama:` during migration
- write newly selected Ollama models back as prefixed IDs
- gradually normalize existing persisted conversation and selection records

## Main risks

1. ID collisions
   - `llama3.2` may exist in both Ollama and LM Studio
   - unprefixed remote IDs will become ambiguous

2. Settings sprawl
   - a new standalone LM Studio card beside Ollama and OpenCode will make the screen feel fragmented
   - solve this by consolidating self-hosted remote providers under one section

3. API behavior mismatch
   - LM Studio's `/api/v1/chat` and `/api/v1/models` are similar in shape to other REST APIs, but not identical to Ollama toolkit abstractions
   - avoid trying to force LM Studio through `OllamaConnectionManager`

4. Streaming differences
   - chunk format, end-of-stream signaling, timeout behavior, and cancellation may differ from Ollama
   - isolate that logic in `lm_studio_api_client.dart`

5. Optional model load/unload semantics
   - LM Studio may expose model lifecycle endpoints that Ollama path does not need
   - keep `loadModel` and `unloadModel` optional/no-op safe in `LLMService`

6. Cache semantics
   - current remote cache is effectively an Ollama cache
   - once two remote providers exist, provider-specific cache ownership matters

## Smallest viable migration path

### Phase 1: Minimal support

- Add `lmstudio:` model prefix support
- Add `LMStudioConnectionManager` and `LMStudioLLMService`
- Update `chat_service.dart` routing to use prefix-based dispatch for LM Studio
- Extend `unified_model_service.dart` to include LM Studio models
- Add a compact LM Studio subsection inside the existing Ollama/remote area in Settings
- Add an `LM Studio` subgroup in `ModelsScreen`

This phase avoids changing `InferenceMode` and avoids large storage refactors.

### Phase 2: Remove brittle assumptions

- Introduce `ModelIdService`
- Write new Ollama selections as `ollama:` IDs
- Keep unprefixed IDs readable as legacy Ollama IDs
- Split cached remote model storage by provider

### Phase 3: Clean architecture pass

- Replace Ollama-specific remote connection storage with generic `RemoteConnectionService`
- Replace `Connection` naming with provider-neutral remote naming in UI and services where worthwhile
- Convert `Remote Models` settings area into a provider-switching surface with shared card scaffolding

## Decision summary

LM Studio should be treated as a second self-hosted remote provider, not a new top-level inference mode.

The minimal safe design is:

- keep `InferenceMode.remote`
- add `lmstudio:` model IDs
- route from parsed model source instead of hardcoded prefix branches
- present LM Studio next to Ollama inside a single remote section so the UI stays clean