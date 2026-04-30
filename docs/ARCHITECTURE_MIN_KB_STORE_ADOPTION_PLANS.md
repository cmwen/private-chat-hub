# min-kb-store adoption plans

## Goal

Adapt `private-chat-hub` to use the sibling `min-kb-store` repository as its
primary data store.

This document assumes a **clean-slate migration**:

- existing local app data may be deleted
- backward compatibility with current `SharedPreferences` blobs is optional
- we should optimize for a maintainable target architecture, not for preserving
  old storage formats

## What changes between the two systems

### Current `private-chat-hub` storage

Today the app stores most data as JSON blobs in `SharedPreferences`:

- conversations and nested messages
- projects
- offline queue items
- connection profiles
- inference and tool settings
- remote model caches

This is simple, but it means:

- large conversation writes rewrite one big JSON payload
- attachments are embedded as base64 inside message JSON
- there is no indexed query layer
- sync and conflict handling are weak

### Target `min-kb-store` storage

`min-kb-store` is Markdown-first:

- Markdown files are the source of truth
- a local SQLite index is derived and disposable
- chat history is stored as `SESSION.md` plus immutable turn files
- shared knowledge lives in structured Markdown entries with front matter
- query performance comes from rebuilding `.local/index.sqlite`

This is a better fit for:

- reviewable storage
- conflict-resistant sync
- file-based attachments
- full-text and metadata search

It is a worse fit for:

- direct in-process Flutter access on mobile unless we add a Dart-native layer
  or a local sidecar API

## Design constraints

1. `min-kb-store` is Python-centric today, while `private-chat-hub` is Flutter.
2. The app currently expects synchronous-ish service reads from local storage.
3. Conversations are tightly coupled to app-specific models like `Conversation`,
   `Message`, `Project`, `QueueItem`, and attachment handling.
4. Settings are currently small key-value values; not all of them need the full
   `min-kb-store` treatment.

## Mapping from current app data to `min-kb-store`

### Conversations

Map each conversation to one chat session:

- root: `agents/private-chat-hub/history/<YYYY-MM>/<session-id>/`
- manifest: `SESSION.md`
- transcript: `turns/*.md`

Suggested session metadata:

- `session_id`: current conversation id
- `title`: current conversation title
- `agent_id`: `private-chat-hub`
- summary from last assistant state or first few turns
- optional metadata for `project_id`, `model_name`, and inference mode

### Messages

Map each message to one immutable turn file:

- filename: sortable UTC timestamp + role + random suffix
- body: Markdown message text
- metadata or inline conventions for:
  - app message id
  - message status (`draft`, `queued`, `sending`, `sent`, `failed`)
  - tool call summary
  - attachment references

### Projects

Store each project as a shared Markdown entry, for example under:

- `memory/shared/long-term/<year>/project-<slug>.md`

or in a dedicated project subtree if we extend `min-kb-store`.

Recommended metadata:

- `id`
- `type: long-term`
- `title`
- tags like `["project"]`
- related ids linking project, sessions, and notes

The body can hold:

- description
- system prompt
- instructions
- pinned state
- UI-only attributes like icon and color

### Attachments

Move attachments out of JSON and into files on disk:

- `agents/private-chat-hub/history/<YYYY-MM>/<session-id>/attachments/...`

Turn files should reference attachment paths instead of embedding base64. This
is one of the biggest wins from adoption.

### Offline queue

Two valid choices:

- keep queue state in the app only and derive it from unsent turns
- store queue state in Markdown front matter on draft/queued turn files

The second option fits `min-kb-store` better and survives restarts cleanly.

### Settings and connection profiles

These do **not** need to move into Markdown immediately.

They can stay in `SharedPreferences` unless we explicitly want them to become:

- portable across devices
- reviewable in Git
- queryable from the knowledge index

This leads to the most practical plan split below.

## Plan A: Hybrid adoption for conversation data only

### Summary

Adopt `min-kb-store` for conversations, projects, attachments, and queue state,
but keep app settings and connection profiles in `SharedPreferences`.

### Why this plan exists

This captures most of the architectural value with the least churn:

- chat history gets the biggest storage benefit
- attachments stop bloating preferences
- projects become inspectable Markdown
- small runtime settings stay simple

### Scope

Replace:

- `ChatService` persistence path
- `ProjectService`
- `MessageQueueService`
- attachment storage format

Keep as-is initially:

- `InferenceConfigService`
- `ConnectionService`
- `LmStudioConnectionService`
- `OpenCodeConnectionService`
- tool config and notification prefs

### Implementation approach

1. Add a `KnowledgeStoreService` in Dart that owns:
   - repo root resolution
   - Markdown read/write helpers
   - session and turn file paths
   - attachment path generation
2. Add a small local SQLite index in Flutter mirroring the derived index concept.
3. Replace conversation load/save with file-backed session reads/writes.
4. Refactor `ProjectService` to read/write Markdown project entries.
5. Convert queue items into turn metadata or a small queue manifest.
6. Leave user settings in `SharedPreferences`.
7. On first launch of the new version, clear old keys instead of migrating them.

### Pros

- Fastest path to real adoption
- Lowest app risk
- Preserves simple handling for small preferences
- Removes the biggest current storage pain points

### Cons

- Two storage systems remain
- Search/index coverage is partial
- Architecture is less pure than a full migration

### Best fit

Choose this if we want to ship incrementally and validate the storage model
before moving every preference and profile into Markdown.

## Plan B: Full Dart-native `min-kb-store` port inside the app

### Summary

Recreate the `min-kb-store` model directly in Dart and make it the primary local
store for nearly everything except ephemeral runtime memory.

### Why this plan exists

The sibling repo’s biggest integration weakness for Flutter is that its current
implementation is Python-centric. This plan keeps the storage model while
removing the Python dependency.

### Scope

Migrate nearly all persistent data:

- conversations
- messages
- projects
- attachments
- queue state
- connection profiles
- inference preferences
- tool configuration
- remote model cache

### Implementation approach

1. Create a Dart package or app module implementing:
   - front matter parsing and formatting
   - path conventions
   - entry typing
   - derived scope logic
   - reindex process
2. Store shared knowledge and chat history in the same directory model as
   `min-kb-store`.
3. Create a local SQLite database with:
   - `entries`
   - `entry_tags`
   - `entry_topics`
   - FTS table
4. Replace `StorageService` with a higher-level repository layer:
   - `ConversationRepository`
   - `ProjectRepository`
   - `SettingsRepository`
   - `ConnectionRepository`
5. Update services to depend on repositories instead of raw key-value storage.
6. Add file watchers or explicit refresh calls to update streams and UI.
7. On rollout, delete legacy `SharedPreferences` data and rebuild the new store.

### Pros

- Best long-term architecture
- No Python runtime dependency
- Same storage model across mobile and desktop Flutter targets
- Enables full local search and portable storage

### Cons

- Largest implementation cost
- Requires careful index and file-format work in Dart
- Touches the most services and app initialization code

### Best fit

Choose this if we want `min-kb-store` to be a real product architecture rather
than a compatibility wrapper.

## Plan C: Python sidecar backed by the existing `min-kb-store` repo

### Summary

Keep `min-kb-store` mostly as-is and access it from `private-chat-hub` through a
local sidecar API process.

### Why this plan exists

This minimizes duplicate implementation by reusing the Python code already
present in the sibling repo.

### Scope

The Flutter app would:

- call a local HTTP or command-wrapper API
- ask the sidecar to create/query sessions and memory entries
- stop reading most app data from `SharedPreferences`

### Implementation approach

1. Add a thin API around the sibling repo:
   - create session
   - append turn
   - list sessions
   - query entries
   - create/update project entries
2. Launch the sidecar locally for desktop targets first.
3. Create a Flutter client service that replaces current persistence services.
4. Keep settings local in `SharedPreferences` at first.
5. Delete current chat/project data during rollout.

### Pros

- Reuses the real repository implementation
- Fast to prototype on Linux/macOS/Windows
- Lowest duplication of indexing and schema rules

### Cons

- Weak mobile story
- Requires process management and local API lifecycle handling
- Adds operational complexity and failure modes
- Harder to bundle cleanly for Android

### Best fit

Choose this if the immediate target is desktop-only experimentation or an
internal prototype, not a polished cross-platform app architecture.

## Plan D: Markdown source of truth plus limited app-local metadata store

### Summary

Use `min-kb-store` for durable content and transcripts, but keep a small
app-local SQLite or preferences store for UI metadata that changes often.

### Why this plan exists

Some fields are product-local rather than knowledge-local:

- selected tab
- draft composer state
- transient notification preferences
- UI sort order overrides

This plan avoids overloading the knowledge store with app noise.

### Scope

Move to `min-kb-store`:

- conversations
- messages
- attachments
- project instructions and prompts

Keep app-local:

- ephemeral UI state
- some small settings
- cached view-state optimizations

### Implementation approach

This is similar to Plan A, but more explicit about preserving a separate local
app database for non-knowledge concerns.

### Pros

- Cleaner domain split
- Better performance flexibility
- Avoids forcing every UI preference into Markdown

### Cons

- Requires clearer architectural boundaries
- Slightly more design work than Plan A

### Best fit

Choose this if we want long-term architectural discipline and already expect the
app to keep some product-local state regardless of knowledge storage.

## Comparison

| Plan | Effort | Risk | Mobile fit | Architectural quality | Speed to value |
| --- | --- | --- | --- | --- | --- |
| A. Hybrid conversations-first | Medium | Low-Medium | High | Good | High |
| B. Full Dart-native port | High | Medium | High | Best | Medium |
| C. Python sidecar | Medium | Medium-High | Low | Fair | High for desktop |
| D. Markdown + app-local metadata | Medium-High | Medium | High | Very good | Medium |

## Recommended plan

### Recommendation

Recommend **Plan A first**, with a deliberate path toward **Plan D** or **Plan B**
later.

### Why

Plan A is the best balance for this codebase because:

- current pain is concentrated in conversations, projects, queue state, and
  attachment storage
- the app already has service boundaries that can be refactored one by one
- keeping small preferences in `SharedPreferences` avoids unnecessary churn
- we can delete existing data, so rollout becomes much simpler

After Plan A proves the model, we can decide:

- move toward **Plan D** if we want a permanent split between knowledge and app
  metadata
- move toward **Plan B** if we want full architectural unification in Dart

## Recommended execution roadmap

### Phase 1: establish the new storage boundary

1. Introduce repository interfaces for conversations, projects, and queue state.
2. Stop letting services write directly to `StorageService`.
3. Add a file-based knowledge-store root for the app.

### Phase 2: move conversations and attachments

1. Implement `SESSION.md` and turn file writing.
2. Move attachments to disk files referenced by turns.
3. Rebuild conversation list screens from file-backed reads.

### Phase 3: move projects and queue state

1. Store projects as Markdown entries.
2. Store queued or failed messages as turn metadata or queue manifests.
3. Add a derived index for search and listing.

### Phase 4: clear legacy storage

Since destructive rollout is acceptable:

1. delete legacy conversation/project/queue keys on upgrade
2. keep only the remaining preference keys that still matter
3. add a one-time initialization path that creates the new folder structure

### Phase 5: decide whether to stop at hybrid or continue

After the first release:

- if the architecture feels clean enough, stop at Plan A or D
- if dual storage feels messy, continue to Plan B

## Concrete code impact in `private-chat-hub`

The main refactors would likely land in:

- `lib/services/chat_service.dart`
- `lib/services/project_service.dart`
- `lib/services/message_queue_service.dart`
- `lib/services/storage_service.dart`
- `lib/models/message.dart`
- `lib/models/conversation.dart`
- `lib/models/project.dart`
- `lib/main.dart`

New likely additions:

- `lib/services/knowledge_store_service.dart`
- `lib/repositories/conversation_repository.dart`
- `lib/repositories/project_repository.dart`
- `lib/repositories/queue_repository.dart`
- Markdown/front matter helpers
- local derived-index helpers

## Final recommendation in one sentence

If we want a practical, low-regret adoption path, we should replace chat,
project, queue, and attachment persistence first, keep small preferences local,
and treat a full Dart-native `min-kb-store` port as a second-stage decision.
