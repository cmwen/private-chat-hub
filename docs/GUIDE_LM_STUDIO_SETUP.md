# LM Studio Setup Guide

This guide covers the smallest working setup for connecting Private Chat Hub to LM Studio over its REST API.

## Prerequisites

- LM Studio installed on a desktop or server
- At least one chat model downloaded in LM Studio
- The Android device and LM Studio host on the same network, unless you intentionally expose the server another way

## LM Studio

1. Open LM Studio.
2. Download or load a chat model.
3. Enable the REST API server.
4. Note the host and port. The default local port is usually `1234`.
5. If you enabled API token authentication, copy the token.

## Private Chat Hub

1. Open Settings.
2. Go to Self-Hosted Servers.
3. In the LM Studio card, enter the host and port.
4. Enable HTTPS only if your LM Studio endpoint is actually served over HTTPS.
5. Paste the API token if LM Studio requires one.
6. Select Test & Save.
7. Open the Models screen and choose an LM Studio model.

## Notes

- LM Studio models are stored with an `lmstudio:` model ID prefix so they do not collide with Ollama models.
- LM Studio behaves like another self-hosted provider. It does not add a new top-level inference mode.
- OpenCode remains separate because it is a gateway for cloud providers, not a self-hosted local model server.

## Troubleshooting

If connection test fails:

1. Make sure LM Studio's REST server is running.
2. Verify the host is reachable from the phone.
3. Check the port and whether HTTPS is enabled correctly.
4. If you use an API token, confirm it matches LM Studio's configuration.

If no models appear:

1. Confirm the model is an LLM, not only an embedding model.
2. Load or download the model in LM Studio.
3. Refresh the Models screen in the app.