# Podcast Studio — Text-First NLE

A single-file, browser-based podcast production studio built around a **text-first non-linear editing** paradigm. Write or generate your script, assign voices, render with Google Gemini TTS, and export a finished WAV — all from one HTML file with zero build steps.

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Single File](https://img.shields.io/badge/architecture-single%20file-green.svg)
![No Build](https://img.shields.io/badge/build-none-brightgreen.svg)

---

## Why This Exists

Traditional podcast editors are audio-first: you record, then edit waveforms. But for AI-voiced podcasts, **the script is the source of truth**. Audio is a rendered artifact of text, just like pixels are a rendered artifact of HTML.

Podcast Studio flips the model: your timeline is a sequence of text turns, each bound to a speaker and a voice. Change the text, and the turn goes stale. Re-render it. The audio is always downstream of the script.

This borrows concepts from video NLEs (non-linear editors like Premiere, Resolve, etc.) — a source bin, a sequence, an inspector, a transport bar — but replaces clips-on-a-timeline with a vertical, text-driven turn list.

---

## Features

### Script & Editing
- **Import any script format** — paste a multi-speaker script in any language; the parser auto-detects speakers using a language-agnostic frequency heuristic (speakers appear 2+ times, false positives like dialogue fragments don't)
- **LLM script generation** — generate scripts from source materials using Gemini or Claude APIs directly in the app
- **Turn operations** — split (at sentence boundaries), join adjacent turns, duplicate, reorder (move up/down), delete
- **Per-turn text editing** — edit any turn inline; the app tracks staleness (text changed since last render)
- **Source bin** — attach reference materials (articles, briefs, outlines) that feed into LLM script generation
- **Markdown normalization** — handles `**bold**` speaker labels, continuation lines, and edge cases

### Voice & TTS
- **30 Gemini TTS voices** — full roster of Gemini's prebuilt voices (Achernar, Achird, Aoede, Charon, Kore, Zephyr, etc.) with gender labels
- **Per-speaker voice assignment** — each speaker gets their own voice, style prompt, and color coding
- **Per-speaker style prompts** — control delivery style ("speak warmly and slowly", "excited news anchor energy")
- **Global style prompt** — set a project-wide delivery style that applies to all turns
- **Voice preview** — audition any voice before committing
- **Two TTS models** — `gemini-2.5-flash-preview-tts` (fast) and `gemini-2.5-pro-preview-tts` (quality)
- **Multi-language support** — configurable language code (default `id-ID`, supports any BCP-47 code)

### Rendering & Playback
- **Per-turn rendering** — render individual turns; only re-render what changed
- **Render All** — batch render with cancel support, rate-limited at 500ms between calls
- **Staleness detection** — yellow indicator when text has changed since last render; green when audio matches text
- **Turn-level playback** — click any turn to play just that clip
- **Full sequence playback** — play the entire podcast with configurable silence gaps between turns
- **Auto-scroll** — the timeline follows playback, highlighting the active turn
- **Transport bar** — play/pause, progress scrubbing, elapsed/total time display

### Export
- **WAV export** — concatenates all rendered turns with silence gaps into a single WAV file (PCM 16-bit, 24kHz mono)
- Download triggers automatically with the project name as filename

### Project Management
- **Multiple projects** — create, switch between, and delete projects
- **IndexedDB persistence** — all data (project JSON, audio blobs, settings) stored locally in the browser
- **30-second autosave** — never lose work
- **Per-project settings** — TTS model, language, silence gap duration, speakers, sources

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| `Space` | Play / pause full sequence |
| `Enter` | Play selected turn |
| `R` | Render selected turn |
| `↑` / `↓` | Navigate turns |
| `Delete` | Delete selected turn |
| `Ctrl+S` | Save project |

---

## Quick Start

### Prerequisites

- A modern browser (Chrome, Firefox, Edge, Safari)
- A [Google AI Studio](https://aistudio.google.com/) API key (free tier works)
- A local HTTP server (required — `file://` is blocked by CORS)

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/podcast-studio.git
cd podcast-studio
```

### 2. Start a local server

**macOS / Linux:**
```bash
./start.sh
# or manually:
python3 -m http.server 8080
```

**Windows:**
```cmd
start.bat
:: or manually:
python -m http.server 8080
```

**Alternative servers:**
```bash
# Node.js
npx serve .

# PHP
php -S localhost:8080

# Ruby
ruby -run -e httpd . -p 8080
```

### 3. Open in browser

Navigate to `http://localhost:8080/podcast-studio.html`

### 4. Add your API key

Click **⚙ Settings** → paste your Gemini API key → **Save Settings**.

Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey).

### 5. Create your podcast

**Option A — Import a script:**
Click **📥 Import Script** → paste a multi-speaker script → preview the detected speakers and turns → confirm.

**Option B — Generate with AI:**
Add source materials to the Source Bin → click **✨ Generate Script** → describe what you want → the LLM writes the script and auto-imports it.

### 6. Configure voices

Click any speaker in the left panel → assign a voice, set a style prompt → preview it.

### 7. Render & export

Click **Render All** to synthesize audio for every turn → click **⬇ Export WAV** to download.

---

## Architecture

### Single-File Design

The entire application is one self-contained HTML file (~2200 lines, ~80KB). No build step, no bundler, no framework, no dependencies. HTML + CSS + vanilla JS in a single `<script>` tag. This is intentional — it makes the app trivially forkable, auditable, and deployable.

### Three-Panel Layout

```
┌─────────────────────────────────────────────────────────┐
│  Source Bin (left)  │  Sequence (center)  │  Inspector  │
│                     │                     │   (right)   │
│  • Speakers         │  • Turn list        │             │
│  • Sources          │  • Status dots      │  • Turn     │
│                     │  • Waveform canvas  │    editor   │
│                     │  • Context menus    │  • Speaker  │
│                     │                     │    config   │
│                     │                     │  • Source   │
│                     │                     │    editor   │
├─────────────────────┴─────────────────────┴─────────────┤
│  Transport Bar — play/pause, progress, time display     │
└─────────────────────────────────────────────────────────┘
```

### State Model

```javascript
state.project = {
  id,                    // UUID
  name,                  // Project display name
  globalStylePrompt,     // Applied to all TTS calls
  silenceGapMs,          // Silence between turns (default 300ms)
  ttsModel,              // 'gemini-2.5-flash-preview-tts' or 'gemini-2.5-pro-preview-tts'
  language,              // BCP-47 code, e.g. 'id-ID', 'en-US', 'ja-JP'
  speakers: {            // keyed by alias
    alias: { displayName, voiceId, defaultStyle, colorIdx }
  },
  sources: {             // keyed by id
    id: { label, text }
  },
  turns: [{              // ordered array = the sequence
    id, speakerAlias, text, styleOverride,
    _renderedHash,       // hash of text at last render
    audioDurationMs,     // duration of rendered audio
    _audioBlob,          // PCM Int16Array (transient, not serialized)
    _isRendering,        // true during API call
    _error               // error message if render failed
  }]
}
```

### Turn Status Logic

Each turn has a visual status indicator:

| Status | Dot | Meaning |
|--------|-----|---------|
| `ok` | 🟢 | Audio rendered, text unchanged since render |
| `stale` | 🟡 | Text changed after last render — needs re-render |
| `pending` | ⚪ | No audio rendered yet |
| `rendering` | 🔵 | Currently calling TTS API |
| `error` | 🔴 | Last render failed |

Status is computed from `_renderedHash` vs current text hash. This means you can edit freely and only re-render what changed.

### Storage

All persistence uses IndexedDB with three object stores:

| Store | Key | Value |
|-------|-----|-------|
| `projects` | project ID | Full project JSON (turns, speakers, sources — minus audio blobs) |
| `audio` | `projectId:turnId` | Raw PCM `Int16Array` buffer |
| `settings` | `'global'` | API keys, preferences |

Audio blobs are stored separately from project JSON because they're large and binary. On project load, blobs are reattached to their turns.

### TTS API Integration

The app calls Gemini's `generateContent` endpoint with audio response modality:

```
POST /v1beta/models/{model}:generateContent?key={apiKey}

{
  "contents": [{ "parts": [{ "text": "stylePrompt: turnText" }] }],
  "generationConfig": {
    "responseModalities": ["AUDIO"],
    "speechConfig": {
      "languageCode": "id-ID",
      "voiceConfig": {
        "prebuiltVoiceConfig": { "voiceName": "Kore" }
      }
    }
  }
}
```

Response contains base64-encoded PCM audio at 24kHz 16-bit mono in `candidates[0].content.parts[0].inlineData.data`.

### Script Parser

The parser is language-agnostic and uses a single universal heuristic:

1. **`normalizeScriptText()`** — strips markdown bold (`**text**`, `__text__`)
2. **`detectSpeakers(text)`** — scans every line for `label: text` patterns where label ≤ 3 words; keeps only labels appearing **2+ times**
3. **`parseScript(text, speakerLabels)`** — builds a regex from known speaker labels; speaker tag lines start new turns, all other lines are continuations

The 2+ occurrence rule works because false positives like `"Dan yang paling penting: pendidikan"` appear once, while real speaker labels appear 10-20+ times across a script.

---

## Configuration Reference

### Settings (⚙ modal)

| Setting | Description |
|---------|-------------|
| **Gemini API Key** | Required. Used for both TTS and LLM script generation. Get one free at [AI Studio](https://aistudio.google.com/app/apikey). |
| **Anthropic API Key** | Optional. Enables Claude as an alternative LLM for script generation. |
| **TTS Model** | `gemini-2.5-flash-preview-tts` (faster, cheaper) or `gemini-2.5-pro-preview-tts` (higher quality) |
| **Language** | BCP-47 code. Determines TTS pronunciation and phoneme rules. |
| **Silence Gap** | Milliseconds of silence inserted between turns during playback and export (default: 300ms). |

### Available Voices

All 30 Gemini TTS voices are available:

| Female | Male |
|--------|------|
| Achernar, Aoede, Autonoe, Callirrhoe, Despina, Erinome, Gacrux, Kore, Laomedeia, Leda, Pulcherrima, Sulafat, Vindemiatrix, Zephyr | Achird, Algenib, Algieba, Alnilam, Charon, Enceladus, Fenrir, Iapetus, Orus, Puck, Rasalgethi, Sadachbia, Sadaltager, Schedar, Umbriel, Zubenelgenubi |

### Style Prompts

Style prompts are prepended to the turn text when calling TTS. They control vocal delivery without changing the spoken words. Examples:

- `Speak warmly and conversationally, like a trusted friend`
- `Excited news anchor delivering breaking news`
- `Calm, measured academic explaining a complex topic`
- `Skeptical interviewer pressing for answers`

Set globally (project-wide) and/or per-speaker. Per-turn overrides are also supported via the turn inspector.

---

## Forking & Extending

### Getting Started as a Contributor

```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/podcast-studio.git
cd podcast-studio

# Start dev server
python3 -m http.server 8080

# Edit podcast-studio.html — that's the entire app
# Refresh browser to see changes
```

There is no build step. Edit the HTML file. Reload. That's the dev loop.

### Code Map

The `<script>` tag contains everything, organized top-to-bottom:

| Section | Lines (approx) | Description |
|---------|----------------|-------------|
| Constants | 1–100 | `VOICES`, `MODELS`, `SPEAKER_COLORS` |
| State | 100–130 | `state` object, `settings` object |
| IndexedDB | 130–200 | `openDB()`, `dbGet()`, `dbPut()`, `dbDel()`, `dbGetAll()` |
| Project CRUD | 200–320 | `createDefaultProject()`, `saveProject()`, `loadProject()`, `deleteProject()` |
| Audio Storage | 320–360 | `saveAudioBlob()`, `loadAudioBlob()` |
| Utility | 360–400 | `hashText()`, `uid()`, `toast()` |
| UI Rendering | 400–700 | `renderAll_UI()`, `renderTurnList()`, `renderInspector()`, etc. |
| Turn Operations | 700–850 | `splitTurn()`, `joinTurns()`, `duplicateTurn()`, `moveTurnUp/Down()`, `deleteTurn()` |
| TTS Engine | 850–1000 | `renderTurn()`, `renderAll()`, audio decode pipeline |
| Playback | 1000–1200 | `playTurn()`, `playAll()`, `stopPlayback()`, transport bar |
| Export | 1200–1300 | `exportAudio()`, WAV header generation |
| Script Parser | 1300–1450 | `normalizeScriptText()`, `detectSpeakers()`, `parseScript()` |
| LLM Integration | 1450–1600 | `generateScript()`, `callGemini()`, `callAnthropic()` |
| Import Modal | 1600–1700 | `showImportModal()`, preview logic |
| Settings Modal | 1700–1800 | `showSettings()`, `saveSettings()` |
| Init & Events | 1800–end | `init()`, keyboard handlers, context menus |

### Extension Points

Here are some natural directions for extending the app:

#### Add a new TTS provider

1. Add a new entry to `MODELS` with a provider prefix (e.g., `{id: 'elevenlabs:rachel', label: 'ElevenLabs Rachel'}`)
2. In `renderTurn()`, branch on the model prefix to call a different API
3. Ensure the response is decoded to a PCM `Int16Array` at 24kHz (or resample)

#### Add SRT/transcript export

1. Each turn has `audioDurationMs` and a known position in the sequence
2. Walk the turns array, accumulating timestamps (duration + silence gaps)
3. Format as SRT: `index\nstart --> end\nspeaker: text\n\n`

#### Add drag-to-reorder turns

The turn list already renders drag handles (`.drag-handle`). To implement:
1. Add `dragstart`, `dragover`, `drop` event listeners on `.turn-row` elements
2. On drop, splice the turn from its old index and insert at the new one
3. Call `renderAll_UI()` to refresh

#### Add background music / intro-outro

1. Add a new section in project state: `project.tracks` (array of `{ type: 'music', audioBlob, startMs, durationMs, volume }`)
2. In `exportAudio()`, mix the music track with the speech PCM at the right offset
3. Volume mixing: `outputSample = speechSample + musicSample * volume`

#### Add multi-track horizontal timeline

This is a larger effort, but the groundwork exists:
1. Each turn already has `audioDurationMs` — these become clip widths on a horizontal axis
2. Add a `<canvas>` for the timeline view
3. Draw clips as rectangles, color-coded by speaker
4. Support click-to-select, drag-to-reorder

#### Add real-time collaboration

1. Replace IndexedDB with a shared backend (e.g., Firebase Realtime Database, Supabase)
2. Add conflict resolution for concurrent edits (last-write-wins is simplest)
3. Broadcast turn status changes over WebSocket

### Adding a New LLM Provider

The LLM layer is already abstracted into `callGemini(prompt)` and `callAnthropic(prompt)`. To add a new provider:

```javascript
async function callNewProvider(prompt) {
  const resp = await fetch('https://api.newprovider.com/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${settings.newProviderKey}`
    },
    body: JSON.stringify({
      model: 'their-model-name',
      messages: [{ role: 'user', content: prompt }]
    })
  });
  const data = await resp.json();
  return data.choices[0].message.content; // adjust to provider's response shape
}
```

Then add it to the `generateScript()` function's provider switch.

---

## Browser Compatibility

| Browser | Status | Notes |
|---------|--------|-------|
| Chrome 90+ | ✅ Full support | Recommended |
| Firefox 90+ | ✅ Full support | |
| Edge 90+ | ✅ Full support | Chromium-based |
| Safari 15+ | ✅ Works | IndexedDB and Web Audio API supported |
| Mobile browsers | ⚠️ Usable | Layout is desktop-optimized; functional but tight on small screens |

### Requirements
- **IndexedDB** — for all persistence (projects, audio, settings)
- **Web Audio API** — for playback (AudioContext, decodeAudioData)
- **Fetch API** — for TTS and LLM calls
- **Localhost or HTTPS** — required by Google API CORS policy (`file://` will not work)

---

## Troubleshooting

### "CORS error" or "Failed to fetch"
You're opening the file directly (`file://`). You must serve it through a local HTTP server. Use `start.sh`, `start.bat`, or any HTTP server on localhost.

### "models/gemini-2.5-flash-tts is not found"
Old model name cached in a saved project. The app auto-migrates on load, but if the issue persists, go to **Settings** and re-select the TTS model from the dropdown.

### "The requested combination of response modalities (TEXT) is not supported"
This was a bug in earlier versions where `responseModalities: ['AUDIO']` was missing from the API call. Update to the latest version.

### "No audio data in response"
Check your API key is valid and has the Gemini API enabled. Verify in [AI Studio](https://aistudio.google.com/) that you can generate content. Also ensure you haven't hit rate limits.

### Playback is silent
Check browser autoplay policy — you may need to click somewhere on the page first to unlock the AudioContext. The app attempts to resume the context automatically.

### Audio sounds robotic / wrong language
Make sure the **Language** setting matches the script language. Setting `en-US` for an Indonesian script (or vice versa) will produce poor results.

---

## API Costs

As of March 2026, Gemini TTS via AI Studio's free tier is generous for prototyping:

| Model | Speed | Quality | Rate Limit (free) |
|-------|-------|---------|-------------------|
| `gemini-2.5-flash-preview-tts` | Fast (~1-3s per turn) | Good | Generous free tier |
| `gemini-2.5-pro-preview-tts` | Slower (~3-8s per turn) | Better | Lower free tier |

A typical 30-turn podcast script uses ~30 API calls for full render. Partial re-renders (only stale turns) reduce this significantly.

Check [Google AI Studio pricing](https://ai.google.dev/pricing) for current limits.

---

## Known Limitations

- **No drag-to-reorder** — turn reordering is via move up/down buttons (drag handles are visible but non-functional)
- **No multi-track mixing** — single voice track only; no background music layering yet
- **No SRT/transcript export** — only WAV audio export currently
- **No undo/redo** — destructive operations (delete, split, join) cannot be undone
- **Desktop-optimized** — usable on mobile but the three-panel layout is designed for desktop
- **Single-file limits** — no code splitting, no lazy loading; the entire app loads at once (but it's only ~80KB)
- **Last-write-wins** — no collaborative editing support

---

## Project Structure

```
podcast-studio/
├── podcast-studio.html   # The entire application (single file)
├── start.sh              # macOS/Linux launcher (python3 HTTP server)
├── start.bat             # Windows launcher
├── README.md             # This file
└── LICENSE               # Apache 2.0
```

That's it. One HTML file, two launcher scripts, docs, and a license.

---

## License

Copyright 2026, Christoforus Yoga Haryanto

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

> http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## Contributing

Contributions are welcome. Since this is a single-file app, the contribution model is straightforward:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/srt-export`)
3. Edit `podcast-studio.html`
4. Test locally with `python3 -m http.server 8080`
5. Commit your changes (`git commit -am 'Add SRT export'`)
6. Push to your branch (`git push origin feature/srt-export`)
7. Open a Pull Request

Please keep changes focused — one feature or fix per PR. Since it's a single file, diffs can get noisy; clear commit messages help a lot.

---

## Acknowledgments

- **Google Gemini TTS** — the TTS engine powering voice synthesis
- **Anthropic Claude** — optional LLM backend for script generation
- Built with vanilla HTML, CSS, and JavaScript — no frameworks, no dependencies, no build tools
