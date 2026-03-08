# UX Design: LM Studio Integration

## Goal

Add LM Studio through REST without making the app feel like it gained a new conceptual mode. LM Studio should feel close to Ollama because both are user-managed remote servers, while OpenCode remains distinct as a cloud gateway.

## Recommended UX

### Settings information architecture

- Keep a single remote-server area in Settings.
- Do not add a new top-level Settings card just for LM Studio.
- Rename the current Ollama section to a broader remote label.
- Keep OpenCode as its own separate card because it is a different mental model: one authenticated gateway to many cloud providers.

Recommended structure:

1. Remote Connections
2. OpenCode Connection
3. On-Device Models

### Remote Connections behavior

- Show Ollama and LM Studio in the same list.
- Each connection row should show a small source badge: Ollama or LM Studio.
- Primary action should become Add Server, not Add Connection.
- Tapping Add Server should open one flow with a simple Server Type field at the top:
  - Ollama
  - LM Studio
- Reuse the same connection form wherever possible so the UI still feels familiar.
- Only show provider-specific helper text when needed.

### Inference mode

- Keep three top-level inference modes.
- Do not add a fourth card for LM Studio.
- Rename the current Remote card so it covers both Ollama and LM Studio.

Recommended remote card framing:

- Title: Remote
- Subtitle: Run models on an Ollama or LM Studio server

### Models screen

- Replace the Ollama-only group with a broader Remote Models group.
- Keep On-Device Models and OpenCode Models as separate groups.
- Within Remote Models, distinguish each item with:
  - a source badge: Ollama or LM Studio
  - the connection name or host as secondary metadata
- Avoid splitting Ollama and LM Studio into two top-level sections unless there is a strong operational difference later.

This keeps the main grouping aligned with user intent:

- Remote models
- On-device models
- Cloud gateway models

## Exact wording

### Settings headers

- Remote Connections
- OpenCode Connection
- On-Device Models

### Settings helper text

For the Remote Connections section:

- Connect to Ollama or LM Studio to run models on your own server.

Empty state:

- No remote servers configured
- Add an Ollama or LM Studio server to get started.

For OpenCode, keep the mental model distinct:

- Connect to an OpenCode server to access cloud models through a single gateway.

### Buttons and labels

- Add Server
- Server Type
- Ollama
- LM Studio
- Test Connection
- Save Server
- Set as Default

If you keep one shared form, use neutral field labels:

- Server Name
- Host
- Port
- Use HTTPS

### Inference mode card copy

- Header: Inference Mode
- Remote card title: Remote
- Remote card subtitle: Run models on an Ollama or LM Studio server
- Remote card feature chips:
  - Self-hosted
  - Larger models
  - Server-managed

### Models screen copy

Section headers:

- Remote Models
- On-Device Models
- OpenCode Models

Remote model metadata pattern:

- Badge: Ollama
- Badge: LM Studio
- Secondary line example: Home Server · 192.168.1.20

If a filter is added later, preferred label:

- Source
- All remote sources
- Ollama
- LM Studio

## Rationale

- LM Studio and Ollama are both user-managed remote servers and should share the same conceptual bucket.
- OpenCode remains separate because it behaves like a broker for many hosted providers, not like a single model server.
- Chat already routes by selected model, so adding a separate LM Studio mode would create redundant decision-making.
- A single Remote grouping reduces scanning cost and avoids a Settings page that keeps growing one provider card at a time.

## Acceptance checklist

- There is still only one remote/local-server area in Settings.
- LM Studio does not add a new top-level inference mode.
- OpenCode remains visually distinct from self-hosted servers.
- Users can tell whether a remote model comes from Ollama or LM Studio in one glance.
- The primary labels use broad terms like Remote or Server where appropriate, not vendor-specific wording that will age badly.
- Empty states and helper text explain both Ollama and LM Studio without adding more than one extra sentence.
- The Settings screen can be understood without reading long paragraphs or opening multiple nested dialogs.