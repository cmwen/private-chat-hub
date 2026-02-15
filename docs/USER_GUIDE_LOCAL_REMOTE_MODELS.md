# User Guide: Local & Remote Models with Offline Support

## Overview

This guide explains how to use Private Chat Hub's unified model system that seamlessly combines local (on-device) and remote (Ollama) AI models with automatic offline message queueing.

**Target Audience:** End users  
**Last Updated:** January 25, 2026  
**Related Documents:**
- [UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md](UX_DESIGN_LOCAL_REMOTE_MODEL_SYSTEM.md)
- [ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md](ARCHITECTURE_LOCAL_REMOTE_MODEL_SYSTEM.md)

---

## What's New

### Unified Model Selection
- **One List:** All models (local and remote) in a single selector
- **Easy Switching:** Change models anytime without configuration
- **Smart Icons:** Visual indicators show model type

### Offline Support
- **Auto-Queue:** Messages queue automatically when offline
- **Auto-Send:** Queued messages send when connection returns
- **No Lost Messages:** Everything is saved and retried

### Local Models
- **Privacy:** Runs entirely on your device
- **Offline:** Works without internet/server
- **Fast:** Optimized for mobile hardware

---

## Getting Started

### 1. Selecting a Model

**From Conversation List:**

1. Tap the **model name** at the top or **"New Conversation"**
2. See list of all available models:
   - 🌐 **Remote models** (require Ollama server)
   - 📱 **Local models** (run on your device)
3. Tap any model to select it
4. If local model isn't downloaded, you'll see a download option

**Example List:**

```
┌─────────────────────────────────────┐
│ Select Model                        │
├─────────────────────────────────────┤
│ 🌐 llama3:latest                    │
│    8B parameters                    │
│                                     │
│ 🌐 mistral:latest                   │
│    7B parameters                    │
│                                     │
│ 📱 Gemma 3 1B         [On-Device]   │
│    557 MB • Fast                    │
│                                     │
│ 📱 Gemma 3n E2B       [Download]    │
│    2.9 GB • Balanced                │
└─────────────────────────────────────┘
```

### 2. Chatting with Any Model

Once you select a model:

1. Type your message in the input field
2. Tap **Send** (paper plane icon)
3. Your message appears immediately
4. AI response streams in real-time

**The app automatically:**
- Routes to local inference if you selected a local model
- Routes to Ollama if you selected a remote model
- Queues messages if you're offline (remote models only)

### 3. Understanding Connection Status

**Status Banner (top of screen):**

| Icon | Text | Meaning |
|------|------|---------|
| ● (green) | Connected to Ollama | Online, remote models work |
| ● (orange) | Ollama Offline | Remote models queue, local models still work |
| 📱 | Using Local Model | Running on your device |
| ⚠️ | Connection Error | Check Ollama settings |

**You can dismiss the banner** by tapping the × button. It will reappear if the status changes.

---

## Working Offline

### Automatic Message Queueing

When you lose connection while using a **remote model**:

1. Continue typing and sending messages normally
2. Messages are automatically queued
3. A banner shows: **"Offline • X messages queued"**
4. Each queued message shows a 📤⏳ icon

**Example:**

```
┌──────────────────────────────────────────────┐
│ 🔌 Offline • 3 messages queued               │
│                                              │
│ Messages will send automatically when        │
│ connection is restored                       │
│                                              │
│         [Retry Now]  [View Queue]           │
└──────────────────────────────────────────────┘
```

### When Connection Returns

**Automatic Processing:**

1. Connection restored
2. Banner updates: **"Connected • Sending queued messages..."**
3. Shows progress: **"Sending message 2 of 3"**
4. Each message:
   - Changes to ⌛ (sending)
   - Gets AI response
   - Changes to ✓ (sent)
5. Banner disappears when all sent

**You don't need to do anything!** The app handles it automatically.

### Using Local Models Offline

**Local models work offline automatically!**

If you're using a local model (📱 icon):
- No connection needed
- No queueing
- Works everywhere (airplane, remote areas, etc.)
- Messages send immediately

**Tip:** Download local models for reliable offline use.

---

## Message Status Icons

Messages show status in the bottom-right corner:

| Icon | Meaning | What to Do |
|------|---------|------------|
| ✓ | Sent successfully | Nothing, it worked! |
| 📤⏳ | Queued (will send when online) | Wait or retry now |
| ⌛ | Currently sending | Wait a moment |
| ⚠️ | Failed to send | Tap [Retry] button |

**Tap any message** to see detailed status information.

---

## Managing Local Models

### Downloading Models

**From Model Selector:**

1. Tap a model with **[Download]** button
2. Confirm download (shows size)
3. Download starts with progress bar
4. Can continue using app while downloading
5. Model appears with **[On-Device]** badge when ready

**From Settings:**

1. Open **Settings** → **Manage On-Device Models**
2. See list of **Downloaded** and **Available** models
3. Tap **[Download]** next to any model
4. Track progress in real-time

**Download Times** (on average Wi-Fi):
- Gemma 3 1B (557 MB): ~2 minutes
- Gemma 3n E2B (2.9 GB): ~10 minutes
- Gemma 3n E4B (4.1 GB): ~15 minutes

### Deleting Models

**Free up storage** by removing local models you don't use:

1. **Settings** → **Manage On-Device Models**
2. Find model under **Downloaded**
3. Tap **[×]** button
4. Confirm deletion

**Note:** You can re-download anytime for free.

### Checking Storage

At the bottom of **Manage On-Device Models** screen:

```
Storage: 4.1 GB used of 64 GB available
```

Shows how much space local models are using.

---

## Offline Behavior Settings

### Customizing Offline Experience

**Settings** → **Inference** → **When Offline**

Available options:

☑ **Queue messages automatically**
- Messages queue when offline
- Uncheck to show error instead

☑ **Offer local model fallback**
- Suggests using local model if offline
- Uncheck to just queue

☑ **Show queue status banner**
- Display banner when messages are queued
- Uncheck to hide banner

### Inference Mode

**Settings** → **Inference** → **Inference Mode**

Choose how the app selects inference backend:

- ⚪ **Automatic (Recommended)**
  - Uses local for local models, remote for remote models
  - Seamless experience

- ○ **Remote Only**
  - Always use Ollama server
  - Fails if offline (no queueing)
  - For when you want guaranteed remote

- ○ **Local Only**
  - Only use on-device models
  - Only shows local models in selector
  - Maximum privacy

**Default:** Automatic (recommended for most users)

---

## Common Scenarios

### Scenario 1: Commuting with Spotty Connection

**Problem:** Train/subway has intermittent connection

**Solution:**
1. Select a **local model** before commuting
2. Chat normally throughout journey
3. No connection needed
4. Or use remote model and let messages queue

### Scenario 2: Privacy-Sensitive Conversation

**Problem:** Don't want data leaving device

**Solution:**
1. Select any **local model** (📱 icon)
2. Everything runs on your device
3. No server connection used
4. Data stays private

### Scenario 3: Working from Café

**Problem:** Public Wi-Fi is unreliable

**Options:**

**Option A:** Use local model
- Download once at home
- Use anywhere without worrying

**Option B:** Use remote model
- Messages queue when connection drops
- Automatically send when connected

### Scenario 4: Forgot to Start Ollama

**Problem:** Ollama server not running

**What happens:**
1. App detects server offline
2. Shows banner: **"Ollama Offline"**
3. Messages automatically queue
4. Start Ollama when ready
5. Tap **[Retry Now]** or wait
6. Messages send automatically

---

## Troubleshooting

### Messages Stuck in Queue

**Symptoms:** Messages show 📤⏳ but not sending

**Solutions:**

1. **Check connection:**
   - Is Ollama running?
   - Can you reach the server?
   - Tap status banner to refresh

2. **Manual retry:**
   - Tap **[Retry Now]** in banner
   - Or tap individual message → **[Retry]**

3. **View queue:**
   - Tap **[View Queue]** in banner
   - See all queued messages
   - Retry or cancel individual messages

### Message Shows Failed (⚠️)

**Symptoms:** Message has ⚠️ icon and [Retry] button

**Reasons:**
- Connection lost during sending
- Server error
- Timeout
- Max retries exceeded (3 attempts)

**Solutions:**

1. **Retry:**
   - Tap **[Retry]** button on message
   - Tries to send again immediately

2. **Check server:**
   - Verify Ollama is running
   - Test connection in Settings

3. **Switch to local:**
   - If urgent, select local model
   - Resend message

### Local Model Not Working

**Symptoms:** Selected local model but messages fail

**Solutions:**

1. **Check download:**
   - **Settings** → **Manage On-Device Models**
   - Verify model shows **[On-Device]** badge
   - If not, download completed

2. **Restart app:**
   - Close and reopen app
   - Model may need to reload

3. **Check storage:**
   - Ensure enough free space
   - Check storage indicator

4. **Re-download:**
   - Delete model
   - Download again

### Download Stuck or Failed

**Symptoms:** Model download not progressing

**Solutions:**

1. **Check connection:**
   - Need stable Wi-Fi for large downloads
   - Avoid cellular (data charges)

2. **Retry download:**
   - Tap **[Download]** again
   - Download resumes from where it stopped

3. **Clear partial download:**
   - Delete model
   - Start fresh download

---

## Tips & Best Practices

### For Reliability

1. **Download local models at home**
   - Use Wi-Fi to avoid data charges
   - Have backup for offline situations

2. **Keep 1-2 local models downloaded**
   - Gemma 3 1B: Fast, lightweight (557 MB)
   - Gemma 3n E2B: Balanced (2.9 GB)

3. **Check storage regularly**
   - Delete unused models
   - Keep space for app data

### For Performance

1. **Use local models for quick responses**
   - Faster than network round-trip
   - No latency

2. **Use remote models for complex tasks**
   - More powerful models
   - Better quality for difficult questions

3. **Close unused conversations**
   - Keeps app responsive
   - Manages memory better

### For Privacy

1. **Use local models for sensitive data**
   - Everything on device
   - No server logs

2. **Check connection status**
   - Ensure using local when needed
   - Green light = using Ollama

3. **Clear conversations when done**
   - Manage conversation data
   - Delete sensitive chats

---

## FAQ

### Can I use local models without internet?

**Yes!** Local models work completely offline. Once downloaded, they need no internet connection.

### Do local models use my data plan?

**Only for download.** After downloading, local models use zero data. Only remote models use data when sending messages.

### How much storage do local models need?

- Small: 500 MB - 1.5 GB (Gemma 3 1B, Qwen)
- Medium: 2.5 - 3 GB (Gemma 3n E2B)
- Large: 3.5 - 4 GB (Gemma 3n E4B, Phi-4)

### Can I delete and re-download models?

**Yes!** Delete anytime to free space. Re-download later at no cost.

### What happens to queued messages if I close the app?

**They're saved!** Queue persists even if you close the app. Messages send when:
- You reopen the app AND
- Connection is available

### Can I reorder queued messages?

**Not yet.** Messages send in the order they were queued (FIFO - First In, First Out).

### How many messages can be queued?

**Maximum 50 messages** per conversation. After that, you'll see an error and need to wait or clear the queue.

### Do local models work as well as remote?

**Different use cases:**
- **Local:** Faster, private, offline, but smaller models
- **Remote:** More powerful, but needs connection

For many tasks, local models work great!

### Can I use both local and remote in the same conversation?

**Not yet.** Each conversation uses one model. You can create multiple conversations with different models.

### What if my local model is deleted while in use?

**The app will notify you** when you try to send. You'll be prompted to select a new model.

---

## Keyboard Shortcuts (Desktop)

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + N` | New conversation |
| `Ctrl/Cmd + M` | Change model |
| `Ctrl/Cmd + R` | Retry failed/queued messages |
| `Ctrl/Cmd + ,` | Open settings |
| `Enter` | Send message |
| `Shift + Enter` | New line |
| `Esc` | Close dialog/sheet |

---

## Visual Guide

### Model Icons

| Icon | Type | Meaning |
|------|------|---------|
| 🌐 | Remote | Uses Ollama server, needs connection |
| 📱 | Local | Runs on device, works offline |

### Model Badges

| Badge | Meaning |
|-------|---------|
| [On-Device] | Downloaded and ready to use |
| [Download] | Available to download |
| [▓▓▓░░ 65%] | Currently downloading (65% complete) |

### Message Icons

| Icon | Status |
|------|--------|
| ✓ | Sent successfully |
| 📤⏳ | Queued, will send when online |
| ⌛ | Currently sending |
| ⚠️ | Failed (tap to retry) |

---

## Getting Help

### In-App Support

1. **Settings** → **Help & Support**
2. View common issues and solutions
3. Access this user guide
4. Report issues

### Model-Specific Help

**For local models:**
- Check [Manage On-Device Models](#managing-local-models)
- Verify download and storage
- Ensure model is loaded

**For remote models:**
- Check Ollama connection in Settings
- Verify server is running
- Test connection

### Connection Issues

**Banner shows status:**
- Green: All good
- Orange: Offline but queueing
- Red: Error, check settings

**Manual check:**
1. **Settings** → **Connections**
2. Tap **Test Connection**
3. See detailed error if failed

---

## Glossary

**Local Model:** AI model running on your device (📱 icon)

**Remote Model:** AI model running on Ollama server (🌐 icon)

**Queue:** List of messages waiting to send when offline

**Queued Message:** Message saved to send later (📤⏳ icon)

**On-Device:** Same as local model

**Ollama:** Open-source LLM server for running AI models

**LiteRT:** Google's on-device AI runtime

**Streaming:** Real-time response as it's being generated

---

## Appendix: Model Comparison

### Available Local Models

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| Gemma 3 1B | 557 MB | ⚡⚡⚡ | ⭐⭐ | Quick answers, low storage |
| Gemma 3n E2B | 2.9 GB | ⚡⚡ | ⭐⭐⭐ | Balanced use |
| Gemma 3n E4B | 4.1 GB | ⚡ | ⭐⭐⭐⭐ | High quality responses |
| Phi-4 Mini | 3.6 GB | ⚡⚡ | ⭐⭐⭐⭐ | Code and technical |
| Qwen2.5 1.5B | 1.5 GB | ⚡⚡⚡ | ⭐⭐⭐ | Multilingual support |

### Choosing a Model

**Need offline access?** → Download any local model

**Low storage?** → Gemma 3 1B (557 MB)

**Balanced needs?** → Gemma 3n E2B (2.9 GB)

**Best quality?** → Gemma 3n E4B (4.1 GB) or Phi-4 Mini

**Code/technical?** → Phi-4 Mini

**Multiple languages?** → Qwen2.5 1.5B

**Maximum power?** → Use remote Ollama models (llama3, mistral, etc.)

---

## Updates & Changes

This document will be updated as new features are added:

- **Model selection improvements**
- **Queue management features**
- **New local models**
- **Performance enhancements**

Check **Settings** → **About** for latest app version and changelog.

---

**End of User Guide**
