# UX Design: OpenCode Provider Integration

**Document Version:** 1.0  
**Created:** January 2026  
**Status:** Design Specification  
**Author:** UX Design Agent  
**Purpose:** Complete UX specification for adding OpenCode as a third LLM provider alongside Ollama and On-Device (LiteRT)

---

## Table of Contents

1. [Design Overview & Goals](#1-design-overview--goals)
2. [Information Architecture Changes](#2-information-architecture-changes)
3. [Inference Mode Selector Redesign](#3-inference-mode-selector-redesign)
4. [Settings Screen: OpenCode Connection](#4-settings-screen-opencode-connection)
5. [Model Visibility & Filtering (OpenCode)](#5-model-visibility--filtering-opencode)
6. [Models Screen Redesign](#6-models-screen-redesign)
7. [Chat Screen: Model Selector Updates](#7-chat-screen-model-selector-updates)
8. [Visual Language & Iconography](#8-visual-language--iconography)
9. [Interaction Flows](#9-interaction-flows)
10. [Accessibility Specification](#10-accessibility-specification)
11. [Error States & Edge Cases](#11-error-states--edge-cases)
12. [Design Decisions & Rationale](#12-design-decisions--rationale)

---

## 1. Design Overview & Goals

### Context

Private Chat Hub currently supports two LLM providers:
- **Ollama** — Self-hosted server running open models (Llama, Mistral, Phi, etc.)
- **On-Device (LiteRT)** — Models running directly on the Android device

We are adding **OpenCode** as a third provider. OpenCode is a server (`opencode serve`) that acts as a unified gateway to many cloud AI providers (Anthropic Claude, OpenAI GPT, Google Gemini, AWS Bedrock, etc.), each with multiple models. This introduces a new UX challenge: **scale**. Where Ollama might expose 5–15 models and On-Device has 2–5, OpenCode can expose **50+ models from 8+ providers**.

### Design Goals

| # | Goal | Rationale |
|---|------|-----------|
| G1 | **Zero friction for existing users** | Adding OpenCode must not complicate the Ollama/On-Device experience |
| G2 | **Tame the model explosion** | Users must never be overwhelmed by 50+ models in their chat selector |
| G3 | **Clear provider identity** | Users must always know which provider/backend a model comes from |
| G4 | **Consistent patterns** | OpenCode connection settings follow the same card-based pattern as Ollama |
| G5 | **Progressive disclosure** | Basic usage is simple; power features (filtering, capabilities) are discoverable |
| G6 | **Maintain privacy messaging** | OpenCode models route through cloud APIs—make this explicit vs. local/self-hosted |

### User Personas Affected

- **Alex (Privacy Advocate)** — Needs clear indication that OpenCode models go through cloud APIs. May want to avoid them entirely.
- **Jordan (Power User)** — Wants access to Claude Sonnet, GPT-4o, Gemini Pro all in one place. Will heavily use filtering.
- **Sam (Beginner)** — Needs guided experience. Should not see 50 models unless they want to.
- **Maya (Developer)** — Wants to quickly switch between coding models from different providers.

---

## 2. Information Architecture Changes

### Current Architecture
```
App
├── Chats (conversation list + chat screen)
│   └── Model Selector (app bar chip) ← shows Ollama + On-Device models
├── Projects
├── Models ← flat list: On-Device section + Ollama section
└── Settings
    ├── Ollama Connections (card-based)
    ├── On-Device Models (nav to sub-screen)
    ├── Chat (streaming, notifications)
    ├── Appearance (theme)
    ├── Advanced (timeout, tools, LiteRT params)
    ├── LAN Sync
    └── About
```

### New Architecture (with OpenCode)
```
App
├── Chats (conversation list + chat screen)
│   └── Model Selector (app bar chip) ← shows VISIBLE models from all 3 providers
├── Projects
├── Models ← sectioned list: On-Device / Ollama / OpenCode (grouped by sub-provider)
│   └── OpenCode Model Visibility Settings (gear icon → bottom sheet)
└── Settings
    ├── Connections ← RENAMED section, contains both Ollama and OpenCode
    │   ├── Ollama Connections (existing card-based UI)
    │   └── OpenCode Connection (new card-based UI, single connection)
    ├── Inference Mode ← NEW dedicated section (replaces implicit toggle)
    ├── On-Device Models (nav to sub-screen)
    ├── Chat (streaming, notifications)
    ├── Appearance (theme)
    ├── Advanced (timeout, tools, LiteRT params)
    ├── LAN Sync
    └── About
```

### Key Structural Decisions

1. **Settings: "Connections" becomes a unified section** housing both Ollama and OpenCode connection cards. This groups related concepts and makes room for future providers.

2. **Inference Mode gets its own section** because a toggle/dropdown hidden in Advanced is no longer sufficient for 3 options. It needs first-class visibility.

3. **Model visibility settings live on the Models screen**, not in Settings. Users think about model curation when they're looking at models, not when they're configuring connections.

---

## 3. Inference Mode Selector Redesign

### Current State
The existing `InferenceModeSelector` widget renders two tappable cards (Remote/On-Device) with a radio-style selection. This pattern works well for 2 options but needs adaptation for 3.

### New Design: Three-Option Segmented Cards

**Location:** Settings screen, as a new first-class section titled "Inference Mode" placed between the Connections section and the Chat section.

**Also accessible from:** A quick-switch control in the Models screen header.

#### Layout Specification

```
┌─────────────────────────────────────────────────────────────┐
│  Inference Mode                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☁️  Ollama                                    (●)  │    │
│  │  Self-hosted open models on your server              │    │
│  │  ┌──────────┐ ┌──────────────┐ ┌────────────────┐   │    │
│  │  │ 30+ models│ │ 70B+ capable │ │ Server-managed │   │    │
│  │  └──────────┘ └──────────────┘ └────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  📱  On-Device (LiteRT)                  Preview ○  │    │
│  │  Run models directly on your phone                   │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────┐   │    │
│  │  │ Fully private │ │ Works offline │ │ No server  │   │    │
│  │  └──────────────┘ └──────────────┘ └────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🔗  OpenCode                                   ○   │    │
│  │  Access Claude, GPT, Gemini & more via OpenCode      │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────┐   │    │
│  │  │ Many providers│ │ Latest models │ │ Cloud APIs │   │    │
│  │  └──────────────┘ └──────────────┘ └────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Widget Specification

- **Container:** Three `Card` widgets stacked vertically with 8dp spacing, 16dp horizontal margin.
- **Selection indicator:** Radio circle on the right (filled = selected, outlined = unselected). The selected card gets a 2dp `colorScheme.primary` border and slight elevation (2dp). Unselected cards get a 1dp `colorScheme.outlineVariant` border and no elevation.
- **Icon area:** 48×48dp rounded rectangle with `colorScheme.primaryContainer` (selected) or `colorScheme.surfaceContainerHighest` (unselected). Contains the provider icon.
- **Title:** `titleMedium` weight 600. Shows provider name.
- **Subtitle:** `bodyMedium` in `colorScheme.onSurfaceVariant`. One-line description.
- **Feature chips:** `Wrap` of small `Container` pills with `labelSmall` text inside `colorScheme.surfaceContainerHighest` rounded rectangles (8dp radius).
- **Badge:** The "Preview" badge on On-Device uses `colorScheme.tertiaryContainer` with `colorScheme.onTertiaryContainer` text (matching existing pattern).
- **New badge for OpenCode:** Show "New" badge in `colorScheme.tertiaryContainer` for the first few weeks after launch.
- **Disabled state:** If OpenCode connection is not configured, the card shows a subtle "Not configured" note and tapping it opens a snackbar: "Configure OpenCode in Settings → Connections first."

#### Interaction

1. User taps any card → mode changes immediately.
2. `InferenceConfigService` persists the selection.
3. If switching to a mode with no configured connection (e.g., OpenCode not set up), show a snackbar with action: "OpenCode not configured. **Set Up**" that navigates to Settings.
4. The chat screen's model selector re-filters to show only models from the active provider.
5. The last-used model per mode is remembered and restored on switch.

#### InferenceMode Enum Update

```dart
enum InferenceMode {
  remote,     // Ollama
  onDevice,   // LiteRT
  openCode,   // OpenCode server (NEW)
}
```

---

## 4. Settings Screen: OpenCode Connection

### Section Placement

The Settings screen's "Ollama Connections" section header changes to **"Connections"**. Under it, two sub-sections appear:

```
┌─────────────────────────────────────────────────────────────┐
│  Connections                                                │
│                                                             │
│  ── Ollama ──────────────────────────────────────────       │
│  [Existing Ollama connection cards — unchanged]             │
│  [+ Add Connection]                                         │
│                                                             │
│  ── OpenCode ────────────────────────────────────────       │
│  [OpenCode connection card OR setup prompt]                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Sub-Section Headers

Introduce a lightweight sub-section header widget (smaller than `_SectionHeader`):

```
_SubSectionHeader:
  Padding: fromLTRB(16, 12, 16, 4)
  Row:
    Icon (size 18, colorScheme.primary)
    SizedBox(width: 8)
    Text (fontSize: 14, fontWeight: w600, colorScheme.onSurfaceVariant)
```

- Ollama sub-section: `Icons.cloud` + "Ollama"
- OpenCode sub-section: `Icons.hub` + "OpenCode"

### OpenCode Connection Card

**When not configured (empty state):**

```
┌─────────────────────────────────────────────────────────────┐
│  Card (margin: horizontal 16)                               │
│                                                             │
│      🔗                                                     │
│      OpenCode not configured                                │
│      Connect to access Claude, GPT, Gemini & more          │
│                                                             │
│      [Set Up OpenCode]  (ElevatedButton.icon)               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Icon: `Icons.hub`, size 48, `colorScheme.outline`
- Title: fontSize 16
- Subtitle: `colorScheme.onSurfaceVariant`
- Button triggers the **Add OpenCode Connection Dialog**.

**When configured:**

```
┌─────────────────────────────────────────────────────────────┐
│  Card (margin: horizontal 16, vertical 8)                   │
│                                                             │
│  ┌───────┐                                                  │
│  │  🔗   │  OpenCode Server           ┌─────────┐  ⋮      │
│  │(avatar)│  https://192.168.1.50:3000 │Connected│         │
│  └───────┘                             └─────────┘          │
│                                                             │
│            🔑 Authenticated as admin                        │
│            ✓ Last connected: 5m ago                         │
│            📦 42 models available (18 visible)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Card Components

- **Avatar:** `CircleAvatar` with `Icons.hub`. Background is `colorScheme.primary` (to match Ollama's active connection styling).
- **Title:** "OpenCode Server" (or user-given name).
- **Subtitle:** The full URL (e.g., `https://192.168.1.50:3000`).
- **Status badge:** Inline `ConnectionStatusIndicator`-style chip (reuse the existing pattern):
  - Connected → green chip, "Connected"
  - Disconnected → grey chip, "Disconnected"
  - Error → red chip, "Error"
- **Auth line:** `Icons.key` + "Authenticated as {username}" — only shown if username is configured.
- **Last connected:** Same format as Ollama cards (`Icons.check_circle`, `_formatDate`).
- **Model count:** `Icons.inventory_2` + "{total} models available ({visible} visible)" — helps users understand their curation state.
- **Overflow menu (⋮):** `PopupMenuButton` with:
  - "Test Connection" → tests and shows snackbar
  - "Edit Connection" → opens edit dialog
  - "Manage Visible Models" → navigates to Models screen with OpenCode filter active
  - "Delete Connection" → confirmation dialog then removes

### Add/Edit OpenCode Connection Dialog

Opens as a full-screen dialog (not `AlertDialog`) because it has more fields than the Ollama dialog and benefits from more space.

```
┌─────────────────────────────────────────────────────────────┐
│  ← Set Up OpenCode Connection                               │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ℹ️  OpenCode connects to cloud AI providers like     │    │
│  │    Anthropic, OpenAI, and Google. Your messages      │    │
│  │    will be sent through these external APIs.         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Server URL                                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🌐  192.168.1.50                                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Port                                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ #   3000                                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ☐  Use HTTPS                                               │
│     Enable for secure connections                           │
│                                                             │
│  ── Authentication (Optional) ───────────────────────       │
│                                                             │
│  Username                                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 👤  admin                                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Password                                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔒  ••••••••                               👁       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌──────────────────┐                                       │
│  │ 📡 Test Connection│  ✅ (result icon appears here)       │
│  └──────────────────┘                                       │
│                                                             │
│  ──────────────────────────────────────────────────────     │
│               [Cancel]          [Save Connection]           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Field Specifications

| Field | Type | Default | Validation | Prefix Icon |
|-------|------|---------|------------|-------------|
| Server URL (Host) | `TextFormField` | (empty) | Required, valid hostname/IP | `Icons.dns` |
| Port | `TextFormField` | `3000` | Required, 1–65535 | `Icons.numbers` |
| Use HTTPS | `SwitchListTile` | `false` | — | — |
| Username | `TextFormField` | (empty) | Optional | `Icons.person` |
| Password | `TextFormField` | (empty) | Optional, obscured with toggle | `Icons.lock` |

#### Privacy Notice Banner

At the top of the dialog, a `Card` with `colorScheme.tertiaryContainer` background:

```dart
Card(
  color: colorScheme.tertiaryContainer,
  child: Row(
    children: [
      Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
      Text('OpenCode connects to cloud AI providers...'),
    ],
  ),
)
```

This addresses Alex's (Privacy Advocate) needs—explicit about cloud routing.

#### Test Connection Behavior

1. User taps "Test Connection".
2. Button shows `CircularProgressIndicator` (same as Ollama dialog).
3. On success: ✅ icon appears + the dialog fetches and shows the count of available models/providers as a success summary: "Connected! Found 42 models from 6 providers."
4. On failure: ❌ icon + inline error text with specific guidance:
   - "Connection refused" → "Is `opencode serve` running?"
   - "401 Unauthorized" → "Check username and password."
   - "Timeout" → "Server not reachable. Check host and port."

#### Data Model

```dart
class OpenCodeConnection {
  final String id;
  final String host;
  final int port;
  final bool useHttps;
  final String? username;
  final String? password; // stored securely (flutter_secure_storage)
  final DateTime createdAt;
  final DateTime? lastConnectedAt;
  final int? availableModelCount; // cached from last successful connection
  
  String get url => '${useHttps ? 'https' : 'http'}://$host:$port';
}
```

---

## 5. Model Visibility & Filtering (OpenCode)

This is the **most important UX challenge** in the integration. OpenCode can expose 50+ models from 8+ providers. Without curation, the model selector in chat becomes unusable.

### Design Philosophy

**Default state: All models are HIDDEN.** When a user first connects OpenCode, no models appear in the chat selector. Instead, the user is guided through a curation flow to select which models they want visible. This prevents the "50 models dumped on you" anti-pattern.

After connection, show a one-time prompt:
```
"OpenCode connected! 42 models available. 
Choose which models to show in your chat selector."
[Choose Models]  [Show All]
```

### Where Model Visibility Settings Live

**Primary access: Models screen → OpenCode section → gear icon in section header.**

This opens a **full-screen bottom sheet** (DraggableScrollableSheet, same as existing `CapabilityInfoPanel` pattern) with the model curation UI.

**Secondary access: Settings → Connections → OpenCode card → overflow menu → "Manage Visible Models".**

### Model Visibility Settings Layout

The bottom sheet is the core of the OpenCode model management experience.

```
┌─────────────────────────────────────────────────────────────┐
│  ━━━━━━━━  (drag handle)                                    │
│                                                             │
│  🔗 OpenCode Models                              ✕ Close   │
│  42 models available • 18 visible                           │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  ┌─── Quick Actions ──────────────────────────────────┐     │
│  │  [Show All]  [Hide All]  [Recommended]             │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌─── Filter by Capability ───────────────────────────┐     │
│  │  [🔧 Tools] [👁 Vision] [🧠 Reasoning] [💰 Free]  │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  🔍 Search models...                                        │
│                                                             │
│─── Anthropic (5 models) ─────────────── [Toggle All] ──────│
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☑ Claude 4 Sonnet                                  │    │
│  │    claude-4-sonnet-20250514                          │    │
│  │    [🔧 Tools] [👁 Vision] [🧠 Reasoning] [200K]     │    │
│  │    💰 $3/$15 per 1M tokens                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☑ Claude 4 Opus                                    │    │
│  │    claude-4-opus-20250514                            │    │
│  │    [🔧 Tools] [👁 Vision] [🧠 Reasoning] [200K]     │    │
│  │    💰 $15/$75 per 1M tokens                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☐ Claude 3.5 Haiku                                 │    │
│  │    claude-3-5-haiku-20241022                         │    │
│  │    [🔧 Tools] [👁 Vision] [128K]                     │    │
│  │    💰 $0.80/$4 per 1M tokens                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│─── OpenAI (8 models) ──────────────── [Toggle All] ────────│
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☑ GPT-4o                                           │    │
│  │    gpt-4o-2024-08-06                                 │    │
│  │    [🔧 Tools] [👁 Vision] [128K]                     │    │
│  │    💰 $2.50/$10 per 1M tokens                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ... (more models) ...                                      │
│                                                             │
│─── Google (6 models) ──────────────── [Toggle All] ────────│
│  ... (more providers) ...                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Hierarchy (Model Visibility Sheet)

```
DraggableScrollableSheet (initialSize: 0.85, min: 0.5, max: 0.95)
└── Container (colorScheme.surface, top-rounded 20dp)
    ├── DragHandle (40×4dp, outlineVariant, centered)
    ├── Header Row
    │   ├── Icon (Icons.hub, primary, 24dp)
    │   ├── Column
    │   │   ├── Text "OpenCode Models" (titleLarge, bold)
    │   │   └── Text "{total} models • {visible} visible" (bodyMedium, onSurfaceVariant)
    │   └── IconButton (Icons.close)
    ├── Divider
    └── Expanded → ListView
        ├── QuickActionsRow (padding: 16dp horizontal)
        │   ├── ActionChip "Show All" (Icons.visibility)
        │   ├── ActionChip "Hide All" (Icons.visibility_off)
        │   └── ActionChip "Recommended" (Icons.auto_awesome) ← selects a curated set
        ├── FilterChipsRow (padding: 16dp horizontal)
        │   ├── FilterChip "Tools" (Icons.build_circle)
        │   ├── FilterChip "Vision" (Icons.visibility)
        │   ├── FilterChip "Reasoning" (Icons.psychology)
        │   └── FilterChip "Free Tier" (Icons.money_off)
        ├── SearchField (padding: 16dp)
        │   └── TextField with Icons.search prefix, "Search models..." hint
        └── For each provider group:
            ├── ProviderGroupHeader
            │   ├── ProviderIcon (see §8 Visual Language)
            │   ├── Text "{Provider} ({count} models)" (titleSmall, bold)
            │   └── TextButton "Toggle All" (or "Select All" / "Deselect All")
            └── For each model:
                └── OpenCodeModelTile
                    ├── Checkbox (leading)
                    ├── Column
                    │   ├── Text modelDisplayName (titleMedium, w600)
                    │   ├── Text modelId (bodySmall, onSurfaceVariant, monospace hint)
                    │   ├── CapabilityChips Row (reuse existing _CapabilityChip pattern)
                    │   └── CostLabel (bodySmall)
                    └── (no trailing — checkbox is the interaction)
```

### Model Tile Detail

Each model tile in the visibility list shows:

```
┌─────────────────────────────────────────────────────────────┐
│  ☑  Claude 4 Sonnet                                        │
│     claude-4-sonnet-20250514                                │
│     [🔧 Tools] [👁 Vision] [🧠 Reasoning] [200K ctx]       │
│     💰 $3 / $15 per 1M tokens (input/output)               │
└─────────────────────────────────────────────────────────────┘
```

**Field mapping:**
| Visual Element | Data Source | Widget |
|---------------|-------------|--------|
| Display name | Model display name from OpenCode API | `Text` titleMedium |
| Model ID | Raw model identifier | `Text` bodySmall, monospace style, muted color |
| Capability chips | Parsed from model metadata | `_CapabilityChip` (existing pattern) |
| Context window | From model metadata | `_CapabilityChip` with `Icons.data_object` |
| Cost | From model metadata or static mapping | `Text` with `Icons.payments` prefix |

### Capability Chips (Extended)

Extend the existing `_CapabilityChip` pattern with new chip types for OpenCode:

| Capability | Icon | Label | Color (dark) | Color (light) |
|-----------|------|-------|-------------|---------------|
| Tool Calling | `Icons.build_circle` | "Tools" | `blue.shade200` | `blue.shade700` |
| Vision | `Icons.visibility` | "Vision" | `purple.shade200` | `purple.shade700` |
| Audio | `Icons.mic` | "Audio" | `teal.shade200` | `teal.shade700` |
| Reasoning | `Icons.psychology` | "Reasoning" | `amber.shade200` | `amber.shade700` |
| Context ≥100K | `Icons.data_object` | "{N}K" | `orange.shade200` | `orange.shade700` |
| Extended Thinking | `Icons.lightbulb` | "Thinking" | `yellow.shade200` | `yellow.shade700` |

### Filter Chip Behavior

The filter chips at the top are **Material 3 `FilterChip`** widgets:

- **Unselected:** Outlined, `colorScheme.outline` border.
- **Selected:** Filled with `colorScheme.secondaryContainer`, checkmark shown.
- **Behavior:** Additive filters. Selecting "Tools" + "Vision" shows only models that support BOTH.
- **Clear:** Deselecting all chips shows all models (no filter).
- **Animation:** Standard M3 FilterChip transition (150ms).

### Quick Action Chips

The quick action row uses **`ActionChip`** widgets:

- **"Show All"** → Sets all model checkboxes to checked. Shows confirmation snackbar: "All 42 models now visible."
- **"Hide All"** → Sets all model checkboxes to unchecked. Snackbar: "All models hidden."
- **"Recommended"** → Selects a curated set of ~5–8 models (one flagship per provider). Snackbar: "8 recommended models selected." The recommended set is: Claude Sonnet (latest), GPT-4o, Gemini 2.0 Flash, and the top model from each other connected provider.

### Search Behavior

- **Debounced:** 300ms debounce on text input.
- **Searches:** model display name, model ID, provider name.
- **Results:** Filters the grouped list in real-time. Provider headers hide if they have no matching models.
- **Clear:** X button in text field to clear search.

### Persistence

Model visibility preferences are stored locally via `SharedPreferences`:
- Key pattern: `opencode_model_visible_{modelId}` → `bool`
- Default: `false` (all hidden on first connection)
- The visible model set is also cached alongside the model metadata for offline display.

### "Toggle All" Per Provider

Each provider group header has a "Toggle All" `TextButton`:
- If some or no models in the group are selected → selects all → label says "Select All"
- If all models in the group are selected → deselects all → label says "Deselect All"

---

## 6. Models Screen Redesign

### Current State

The Models screen shows a flat `ListView` with two sections:
- "On-Device Models" — `_LocalModelCard` widgets
- "Ollama Models" — `_ModelCard` widgets

Plus a floating action button: "Pull Model" (for Ollama downloads).

### New Design: Three-Section Layout with Provider Tabs

The Models screen evolves to handle three provider types. Given the potential scale of OpenCode models, we use a **Tab-based approach** to avoid an extremely long scrollable list.

#### Top-Level Layout

```
┌─────────────────────────────────────────────────────────────┐
│  ☁️ Models                                         🔄      │
│─────────────────────────────────────────────────────────────│
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │ All (25) │ │ Ollama(5)│ │OpenCode │                    │
│  │          │ │          │ │  (18)    │                    │
│  └──────────┘ └──────────┘ └──────────┘                    │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  (Tab content — model list for selected tab)                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
│  [📥 Pull Model]  (FAB — shown on Ollama tab only)         │
└─────────────────────────────────────────────────────────────┘
```

**Wait — why tabs?** The existing app uses a flat list with section headers. Tabs are better here because:
1. OpenCode models can number 18+ visible models from 6+ providers — this would push Ollama models far down the list.
2. The FAB "Pull Model" only applies to Ollama, creating confusion on a mixed list.
3. Tabs let users focus on one provider's models at a time.
4. Tab counts give an at-a-glance model inventory.

#### Tab Specification

Use Material 3 `TabBar` with `TabBarView`:

| Tab | Label | Count | Content |
|-----|-------|-------|---------|
| "All" | Shows all providers | Total visible models | Mixed list with section headers (current layout, extended) |
| "Ollama" | Ollama only | Count of Ollama models | Existing `_ModelCard` list + "Pull Model" FAB |
| "On-Device" | On-Device only | Count of local models | Existing `_LocalModelCard` list |
| "OpenCode" | OpenCode only | Count of visible OpenCode models | Grouped-by-provider list with ⚙️ button |

**Note:** The "On-Device" tab only appears if the on-device service is available. The "OpenCode" tab only appears if an OpenCode connection is configured. The "All" tab always appears.

#### "All" Tab Layout

Shows all models from all sources, with section headers and provider badges:

```
┌─────────────────────────────────────────────────────────────┐
│  On-Device Models                                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 📱  Gemma 3 1B                      ✓ Active       │    │
│  │     557 MB • On-Device                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Ollama Models                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ☁️  llama3.2:latest                                 │    │
│  │     3.2 GB • 8B params  [👁 Vision] [🔧 Tools]      │    │
│  └─────────────────────────────────────────────────────┘    │
│  ... (more Ollama models)                                   │
│                                                             │
│  OpenCode Models                                    ⚙️      │
│  ── Anthropic ────────────────────────────────────────      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔗  Claude 4 Sonnet                   Anthropic     │    │
│  │     [🔧 Tools] [👁 Vision] [🧠 Reasoning] [200K]    │    │
│  │     💰 $3/$15 per 1M                                │    │
│  └─────────────────────────────────────────────────────┘    │
│  ── OpenAI ───────────────────────────────────────────      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔗  GPT-4o                             OpenAI       │    │
│  │     [🔧 Tools] [👁 Vision] [128K]                    │    │
│  │     💰 $2.50/$10 per 1M                             │    │
│  └─────────────────────────────────────────────────────┘    │
│  ... (more OpenCode models, grouped by provider)            │
└─────────────────────────────────────────────────────────────┘
```

#### "OpenCode" Tab Layout

This tab shows only visible OpenCode models, grouped by sub-provider, with a gear button to access the model visibility settings.

```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐    │
│  │  18 models visible of 42 available      [⚙️ Manage] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ── Anthropic (3 visible) ─────────────────────────────     │
│  (model cards...)                                           │
│                                                             │
│  ── OpenAI (4 visible) ───────────────────────────────      │
│  (model cards...)                                           │
│                                                             │
│  ── Google (2 visible) ───────────────────────────────      │
│  (model cards...)                                           │
│                                                             │
│  ... (more provider groups)                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The "⚙️ Manage" button opens the Model Visibility bottom sheet from §5.

#### OpenCode Model Card

Each OpenCode model card in the Models screen has a slightly different layout than Ollama cards because OpenCode models are not locally hosted and have different metadata:

```
┌─────────────────────────────────────────────────────────────┐
│  ┌───────┐                                                  │
│  │ Anthr │  Claude 4 Sonnet                      Active    │
│  │  opic │  claude-4-sonnet-20250514                        │
│  │(badge)│  [🔧 Tools] [👁 Vision] [🧠 Reasoning] [200K]   │
│  └───────┘  💰 $3 / $15 per 1M tokens                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- **Leading:** Provider badge (small rounded rectangle with provider initial/abbreviation and brand color — see §8).
- **Title:** Model display name (`titleMedium`, bold).
- **Subtitle line 1:** Model ID in monospace style, muted.
- **Subtitle line 2:** Capability chips (reuse `_CapabilityChip`).
- **Subtitle line 3:** Cost indication.
- **Trailing:** "Active" badge if this is the currently selected model, otherwise empty.
- **Tap action:** Sets as active model (same as Ollama models).
- **Long press or overflow:** Shows bottom sheet with model details.

#### Model Details Bottom Sheet (OpenCode)

When tapping an OpenCode model, show a `DraggableScrollableSheet` (same pattern as existing `_ModelDetailsSheet`):

```
┌─────────────────────────────────────────────────────────────┐
│  ━━━━━━━━                                                   │
│                                                             │
│  🧠 Claude 4 Sonnet                               ✕       │
│  Anthropic • claude-4-sonnet-20250514                       │
│                                                             │
│  ── Capabilities ──────────────────────────────────────     │
│  [✅ Tool Calling]  Description of tool support...          │
│  [✅ Vision]         Can analyze images and screenshots...  │
│  [✅ Reasoning]      Extended thinking for complex tasks... │
│  [❌ Audio]          Not supported                          │
│                                                             │
│  ── Specifications ────────────────────────────────────     │
│  Context Window:     200,000 tokens                         │
│  Max Output:         8,192 tokens                           │
│  Training Cutoff:    April 2025                             │
│                                                             │
│  ── Pricing ───────────────────────────────────────────     │
│  Input:              $3.00 per 1M tokens                    │
│  Output:             $15.00 per 1M tokens                   │
│  Cost Tier:          ●●●○○ (Medium-High)                    │
│                                                             │
│  ── Provider ──────────────────────────────────────────     │
│  Provided by Anthropic via OpenCode                         │
│  ⚠️ Messages are sent to Anthropic's API                    │
│                                                             │
│          [Set as Active Model]                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Chat Screen: Model Selector Updates

### Current State

The chat screen shows a model chip in the app bar. Tapping it opens a model selector that shows Ollama + On-Device models.

### Changes

The model selector dropdown/bottom-sheet now shows models from the **active inference mode only**, grouped by source:

**If mode = Ollama:** Shows Ollama models only (unchanged behavior).
**If mode = On-Device:** Shows local models only (unchanged behavior).
**If mode = OpenCode:** Shows only **visible** OpenCode models, grouped by provider.

#### Model Selector (OpenCode Mode)

```
┌─────────────────────────────────────────────────────────────┐
│  Select Model                                      ✕       │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  ── Anthropic ────────────────────────────────────────      │
│  ○ Claude 4 Sonnet    [🔧][👁][🧠]           $3/$15      │
│  ● Claude 4 Opus      [🔧][👁][🧠]           $15/$75     │
│                                                             │
│  ── OpenAI ───────────────────────────────────────────      │
│  ○ GPT-4o             [🔧][👁]                $2.50/$10   │
│  ○ GPT-4o mini        [🔧][👁]                $0.15/$0.60 │
│  ○ o3                 [🔧][🧠]                $10/$40     │
│                                                             │
│  ── Google ───────────────────────────────────────────      │
│  ○ Gemini 2.5 Pro     [🔧][👁][🧠]           $1.25/$10   │
│  ○ Gemini 2.0 Flash   [🔧][👁]               $0.10/$0.40 │
│                                                             │
│─────────────────────────────────────────────────────────────│
│  ⚙️ Manage visible models                                   │
└─────────────────────────────────────────────────────────────┘
```

**Key elements:**
- Models grouped by provider with lightweight headers.
- Compact capability chips (icon-only, no labels) to save space.
- Cost shown at trailing edge for at-a-glance comparison.
- Radio-button style selection (filled circle = active).
- "Manage visible models" link at the bottom opens the visibility settings.

### App Bar Model Chip

The model chip in the app bar needs a provider indicator:

**Current:** `[llama3.2 ▾]`
**New (Ollama):** `[☁️ llama3.2 ▾]`
**New (On-Device):** `[📱 Gemma 3 1B ▾]`
**New (OpenCode):** `[🔗 Claude 4 Sonnet ▾]`

The icon prefix is a small (14dp) provider-category icon:
- `Icons.cloud` for Ollama
- `Icons.phone_android` for On-Device
- `Icons.hub` for OpenCode

This uses the existing chip pattern but adds a leading icon.

---

## 8. Visual Language & Iconography

### Provider Category Icons

These icons represent the three provider categories throughout the app:

| Provider | Icon | Color (on surfaces) | Semantics Label |
|----------|------|-------------------|-----------------|
| Ollama | `Icons.cloud` | `colorScheme.primary` | "Ollama remote server" |
| On-Device | `Icons.phone_android` | `colorScheme.primary` | "On-device model" |
| OpenCode | `Icons.hub` | `colorScheme.primary` | "OpenCode cloud provider" |

### Sub-Provider Badges (OpenCode)

For OpenCode models, each sub-provider (Anthropic, OpenAI, Google, etc.) gets a small badge:

```dart
Container(
  width: 40, height: 40,
  decoration: BoxDecoration(
    color: providerColor.withOpacity(0.15),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text(
      providerAbbreviation,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: providerColor,
      ),
    ),
  ),
)
```

| Sub-Provider | Abbreviation | Color |
|-------------|-------------|-------|
| Anthropic | "A" | `Color(0xFFD97757)` (Anthropic orange) |
| OpenAI | "AI" | `Color(0xFF10A37F)` (OpenAI green) |
| Google | "G" | `Color(0xFF4285F4)` (Google blue) |
| AWS Bedrock | "AWS" | `Color(0xFFFF9900)` (AWS orange) |
| Mistral | "M" | `Color(0xFFFF7000)` (Mistral orange) |
| Groq | "GQ" | `Color(0xFFF55036)` (Groq red) |
| xAI | "X" | `Colors.grey.shade700` |
| DeepSeek | "DS" | `Color(0xFF4D6BFE)` (DeepSeek blue) |

These colors are used only in the small badge and do not conflict with the app's limited semantic color palette (Decision 8.2). They are **informational**, not actionable.

### Privacy Indicators

To address Alex's needs, OpenCode models carry a subtle but clear privacy indicator:

- **In model cards:** A small `Icons.public` icon next to the provider name, with tooltip: "Messages sent via {Provider} cloud API."
- **In model details:** Full explanation paragraph in the Provider section.
- **In chat:** No persistent indicator during chat to avoid visual noise—but the app bar chip's `Icons.hub` icon serves as a reminder.

### Cost Tier Visualization

OpenCode models may have cost data. Display it as:

**Compact form (in model selector and list):**
```
$3 / $15  ← input/output per 1M tokens
```

**Detailed form (in model details bottom sheet):**
```
Input:  $3.00 per 1M tokens
Output: $15.00 per 1M tokens
Cost Tier: ●●●○○ (Medium-High)
```

**Cost tier dots** (5 dots, filled = higher cost):
| Tier | Dots | Range (output $) |
|------|------|-----------------|
| Free/Very Low | ●○○○○ | $0 – $0.50 |
| Low | ●●○○○ | $0.50 – $5 |
| Medium | ●●●○○ | $5 – $20 |
| High | ●●●●○ | $20 – $50 |
| Very High | ●●●●● | $50+ |

---

## 9. Interaction Flows

### Flow 1: First-Time OpenCode Setup

```
User opens Settings
    ↓
Scrolls to Connections section
    ↓
Sees "OpenCode" sub-section with empty state card
    ↓
Taps "Set Up OpenCode"
    ↓
Full-screen dialog opens
    ↓
Reads privacy notice: "Messages will be sent through external APIs"
    ↓
Enters host, port (HTTPS toggle, optional auth)
    ↓
Taps "Test Connection"
    ↓ (success)
Sees: "Connected! Found 42 models from 6 providers"
    ↓
Taps "Save Connection"
    ↓
Returns to Settings; sees populated OpenCode card
    ↓
One-time prompt appears (bottom of card or snackbar):
"Choose which models to show in your selector"
[Choose Models]
    ↓
Taps "Choose Models"
    ↓
Model Visibility bottom sheet opens (§5)
    ↓
User taps "Recommended" → 8 models selected
    ↓
Closes sheet
    ↓
Goes to Settings → Inference Mode → taps OpenCode card
    ↓
OpenCode is now active inference mode
    ↓
Goes to chat → model chip shows first visible OpenCode model
```

### Flow 2: Switching Inference Modes

```
User is chatting with Ollama (llama3.2)
    ↓
Wants to ask Claude a complex question
    ↓
Opens Settings → Inference Mode
    ↓
Taps OpenCode card
    ↓
Mode switches instantly; last-used OpenCode model restored
    ↓
Returns to chat → model chip shows "🔗 Claude 4 Sonnet"
    ↓
Sends message → routed through OpenCode to Anthropic
    ↓
Later, wants to go back to Ollama
    ↓
Opens Settings → Inference Mode → taps Ollama
    ↓
Returns to chat → model chip shows "☁️ llama3.2"
```

**Alternative quick-switch (future enhancement):**
Long-press the model chip in the chat app bar → shows mode switcher popup. This is noted for future implementation but not part of the initial release.

### Flow 3: Curating Model Visibility

```
User has 42 OpenCode models, 8 visible
    ↓
Goes to Models screen → OpenCode tab
    ↓
Taps "⚙️ Manage" button
    ↓
Visibility sheet opens
    ↓
Scrolls to Google section
    ↓
Taps "Toggle All" → all Google models become visible
    ↓
Sees "Gemini 2.5 Flash" is enabled but user doesn't need it
    ↓
Unchecks Gemini 2.5 Flash
    ↓
Uses search: types "claude"
    ↓
Only Anthropic models shown
    ↓
Enables Claude 3.5 Haiku (was hidden)
    ↓
Closes sheet
    ↓
Model selector now shows the updated set
```

### Flow 4: Selecting an OpenCode Model for Chat

```
User is in OpenCode inference mode
    ↓
Taps model chip in chat app bar
    ↓
Model selector opens (grouped by provider)
    ↓
Sees 18 visible models across 6 providers
    ↓
Taps "GPT-4o" under OpenAI
    ↓
Selector closes; model chip updates to "🔗 GPT-4o"
    ↓
Types a message and sends
    ↓
Message is routed through OpenCode → OpenAI API
    ↓
Streaming response appears (same UX as Ollama streaming)
```

---

## 10. Accessibility Specification

### Screen Reader (TalkBack) Support

All new components must have proper `Semantics`:

| Component | Semantics Label | Semantics Hint |
|-----------|----------------|----------------|
| Inference mode card (Ollama) | "Ollama remote server, {selected/not selected}" | "Double tap to switch to Ollama" |
| Inference mode card (On-Device) | "On-Device LiteRT, preview, {selected/not selected}" | "Double tap to switch to on-device" |
| Inference mode card (OpenCode) | "OpenCode cloud provider, {selected/not selected}" | "Double tap to switch to OpenCode" |
| OpenCode connection card | "OpenCode server, {url}, {connected/disconnected}" | "Double tap for options" |
| Model visibility checkbox | "{model name}, {provider}, {checked/unchecked}" | "Double tap to toggle visibility" |
| Provider group header | "{Provider} section, {count} models" | — |
| Filter chip | "{capability} filter, {selected/not selected}" | "Double tap to toggle filter" |
| Quick action chip | "{action name}" | "Double tap to {action}" |
| Model chip in app bar | "Active model: {name}, provider: {provider}" | "Double tap to change model" |
| Provider badge | "{Provider name}" | — (decorative context only) |
| Cost display | "Cost: {input price} input, {output price} output per million tokens" | — |

### Touch Targets

All new interactive elements meet 48×48dp minimum:
- Model visibility checkboxes: Full tile is tappable (not just the checkbox widget)
- Filter chips: At least 48dp height with adequate spacing
- Quick action chips: Minimum 48dp height
- Provider "Toggle All" buttons: Standard `TextButton` sizing (48dp minimum height)

### Color Contrast

- Provider badge text on badge background: ≥ 4.5:1 contrast ratio
- Capability chip text on chip background: Verified with existing `_CapabilityChip` pattern (already compliant)
- Cost text: Uses `colorScheme.onSurfaceVariant` on `colorScheme.surface` (system-guaranteed contrast)
- Privacy notice text: `colorScheme.onTertiaryContainer` on `colorScheme.tertiaryContainer` (system-guaranteed)

### Keyboard Navigation

For any future desktop/web expansion:
- Tab order follows visual top-to-bottom, left-to-right order
- Enter/Space activates buttons and toggles
- Arrow keys navigate within segmented controls and chip groups
- Escape closes bottom sheets and dialogs

### Text Scaling

All new layouts tested at:
- 1.0x (default) — standard layout
- 1.3x (large) — verify text doesn't overflow, cards expand vertically
- 0.85x (small) — verify text remains readable

The model visibility sheet uses `ListView` so it scrolls naturally if content overflows. Model tile layout uses `Column` with `Wrap` for chips, which handles overflow gracefully.

---

## 11. Error States & Edge Cases

### E1: OpenCode Server Unreachable

**Trigger:** User switches to OpenCode mode but server is down.

**Behavior:**
- Connection status badge shows red "Disconnected" 
- Chat screen shows `ConnectionBanner` (existing pattern): "OpenCode server unreachable. [Retry] [Switch to Ollama]"
- "Switch to Ollama" is a TextButton that changes inference mode

### E2: OpenCode Connected But No Visible Models

**Trigger:** User connects OpenCode but hasn't curated any visible models (or hides all).

**Behavior:**
- Models screen OpenCode tab shows empty state:
  ```
  No models visible
  
  You've connected to OpenCode with 42 models available,
  but none are set to visible.
  
  [Choose Models to Show]
  ```
- Chat model selector shows: "No OpenCode models visible. [Manage Models]"

### E3: OpenCode Auth Failure (401)

**Trigger:** Username/password incorrect or expired.

**Behavior:**
- Connection test shows ❌ with message: "Authentication failed. Check username and password."
- If previously connected and auth expires mid-session: show banner "OpenCode authentication failed. [Update Credentials]"

### E4: Model Removed from OpenCode Server

**Trigger:** A model the user had visible is no longer available from the OpenCode server.

**Behavior:**
- On refresh: model disappears from list
- If it was the active model: snackbar "Claude 3 Opus is no longer available. Switched to Claude 4 Sonnet."
- Auto-switch to first available visible model from the same provider, or first visible model overall

### E5: Network Timeout During Model List Fetch

**Trigger:** OpenCode is slow to respond when fetching available models.

**Behavior:**
- Show cached model list with a subtle "Last updated: 2h ago" note
- Show refresh button
- Do not block the UI

### E6: Inference Mode Switch with Unsaved Chat

**Trigger:** User switches mode mid-conversation.

**Behavior:**
- Mode switches freely—conversations persist regardless of mode
- When user returns to conversation, the model used is whatever was active when the conversation was created
- If the original model is unavailable, offer to continue with a different model

### E7: OpenCode Connection Not Configured But Mode Selected

**Trigger:** User tries to select OpenCode in inference mode selector without configuring a connection.

**Behavior:**
- Snackbar: "OpenCode not configured. **Set Up**" (with action button)
- Action button navigates to Settings → Connections → OpenCode setup
- Inference mode does NOT change (remains on previous selection)

---

## 12. Design Decisions & Rationale

### Decision D1: Default All Models Hidden

**Decision:** When OpenCode is first connected, all models start hidden (not visible in chat selector).

**Rationale:**
- Prevents the "50 models dumped on you" anti-pattern
- Forces intentional curation
- Better first experience: user picks 3-5 models they actually use
- "Recommended" quick-action provides a sensible starting point

**Alternative rejected:** Show all by default with "hide unwanted ones." This front-loads cognitive overload.

### Decision D2: Inference Mode as Exclusive Selection

**Decision:** Only one inference mode is active at a time (Ollama OR On-Device OR OpenCode).

**Rationale:**
- Matches existing architecture (InferenceMode enum is exclusive)
- Simpler mental model: "I'm using X right now"
- Avoids confusion about which backend is handling messages
- Model selector only shows relevant models for the active mode

**Alternative rejected:** "Show all models from all providers in one list." This creates confusion about routing, cost, and privacy. A power user who wants to quickly compare can switch modes.

**Future enhancement:** Allow pinning favorite models from any mode for quick access. Not in initial scope.

### Decision D3: Model Visibility Settings on Models Screen (Not Settings)

**Decision:** The model visibility curation UI is accessed from the Models screen, not from Settings → Connections.

**Rationale:**
- Model curation is a "model management" task, not a "connection configuration" task
- Users think "I want to see/hide models" when they're browsing models
- Keeps Settings focused on connection/infrastructure config
- Secondary access from Settings → OpenCode card → overflow menu still available

### Decision D4: Tab-Based Models Screen

**Decision:** Add tabs (All / Ollama / On-Device / OpenCode) to the Models screen.

**Rationale:**
- Without tabs, OpenCode models would push existing model sections far down
- Different model types have different actions (Pull for Ollama, Download for On-Device, nothing for OpenCode)
- Tab counts provide useful at-a-glance information
- "All" tab preserves the original unified view for users who want it

**Alternative rejected:** Keep flat list. Doesn't scale when OpenCode adds 18+ visible models.

### Decision D5: Full-Screen Dialog for OpenCode Connection

**Decision:** Use a full-screen route (not AlertDialog) for the OpenCode connection setup.

**Rationale:**
- More fields than Ollama (adds username + password)
- Privacy notice banner needs adequate space
- Test Connection result display (model/provider counts) needs room
- Consistent with platform conventions for complex forms

**Alternative considered:** AlertDialog (like Ollama). Works for Ollama's 4 fields but feels cramped with 6 fields + notice + test results. The Ollama dialog itself could be upgraded to full-screen in a future update.

### Decision D6: Provider Badge Colors (Not Icons)

**Decision:** Use colored text abbreviation badges for sub-providers rather than logo icons.

**Rationale:**
- No dependency on provider logo assets (licensing, updates)
- Works in all themes (dark/light)
- Consistent sizing and rendering
- Abbreviations are recognizable ("A" = Anthropic, "AI" = OpenAI, etc.)
- Brand colors are informational, not violating the limited palette rule

### Decision D7: Cost Display

**Decision:** Show cost information on OpenCode models.

**Rationale:**
- Cloud API models have real monetary cost
- Users need this information to make informed choices
- Distinguishes from Ollama/On-Device which are "free after infrastructure cost"
- Compact format ($X/$Y) is scannable; details in bottom sheet

---

## Related Documents

- [UX_DESIGN.md](UX_DESIGN.md) — Original wireframes and specifications
- [UX_DESIGN_DECISIONS.md](UX_DESIGN_DECISIONS.md) — Existing design decisions log
- [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md) — Local/Remote model UX
- [UX_DESIGN_TOOL_TOGGLE_CAPABILITY_DISPLAY.md](UX_DESIGN_TOOL_TOGGLE_CAPABILITY_DISPLAY.md) — Capability display patterns
- [USER_PERSONAS.md](USER_PERSONAS.md) — User persona definitions
- [USER_FLOWS.md](USER_FLOWS.md) — Existing user flow diagrams

---

## Appendix A: Component Reuse Map

| New Component | Reuses From | What Changes |
|--------------|-------------|-------------|
| OpenCode connection card | `_ConnectionCard` in settings_screen.dart | Add auth info, model count, different icon |
| OpenCode connection dialog | `AddConnectionDialog` | Add username/password fields, privacy notice, upgrade to full-screen |
| Inference mode selector | `InferenceModeSelector` widget | Add third card for OpenCode |
| Model visibility checkbox tiles | `ModelDownloadTile` layout | Replace download button with checkbox |
| Capability chips (extended) | `_CapabilityChip` in capability_widgets.dart | Add Reasoning, Thinking chip types |
| Provider group headers | `_SectionHeader` in settings_screen.dart | Smaller size, add provider icon + toggle button |
| OpenCode model cards | `_ModelCard` in models_screen.dart | Add provider badge, cost, different actions |
| Model details bottom sheet | `_ModelDetailsSheet` in models_screen.dart | Add cost, provider, privacy sections |
| Connection status indicator | `ConnectionStatusIndicator` widget | Reuse directly (polymorphic for any provider) |

## Appendix B: Settings Screen Section Order (New)

```
1. Connections
   1a. Ollama (existing cards)
   1b. OpenCode (new card)
2. Inference Mode (NEW section — the 3-option selector)
3. On-Device Models (existing nav tile)
4. Chat (streaming, notifications)
5. Appearance (theme)
6. Advanced (timeout, tools, LiteRT params)
7. LAN Sync
8. About
```

## Appendix C: Data Flow Summary

```
opencode serve (server)
    ↓ HTTP/HTTPS + Basic Auth
OpenCode Connection Service (app)
    ↓ fetches model list
OpenCode Model Cache (SharedPreferences)
    ↓ filtered by visibility preferences
Model Visibility Preferences (SharedPreferences)
    ↓ visible models only
Chat Model Selector / Models Screen
    ↓ user selects model
Chat Service → OpenCode LLM Service
    ↓ sends request to opencode serve
    ↓ which routes to Anthropic/OpenAI/Google/etc.
Streaming Response → Chat Screen
```

---

*This document should be updated as the OpenCode integration progresses and user feedback is incorporated.*
