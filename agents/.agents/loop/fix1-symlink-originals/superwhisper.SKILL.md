---
name: superwhisper
description: >
  Configure and troubleshoot Superwhisper dictation on Linux through its CLI.
  Use when the user asks to change or inspect Superwhisper: processing mode
  (Offline, Offline Lite, Cloud), language, tone, microphone, keyboard shortcuts,
  sound effects, the recording indicator, silence removal, auto-paste, history
  and retention, vocabulary and replacements, offline model downloads, launch at
  login, the Omarchy bar panel, or why dictation is not working. Triggers:
  superwhisper, dictation, speech to text, push to talk, voice typing.
---

# Superwhisper

Superwhisper runs as the user service `superwhisper.service`. Every command below
talks to that service through `~/.local/bin/superwhisper` (on `PATH`) and starts it
when it is not running. Commands print JSON; read it back to confirm a change.
Where they overlap, command names match the macOS and Windows `superwhisper` CLI
(`record`, `start`, `stop`, `read`, `vocab`, `transcribe`, `settings`).

**Change settings through the CLI, never by editing files.** The CLI validates
values, uses revisions so it cannot overwrite a change made elsewhere, and applies
it immediately. The files (`~/.config/superwhisper/preferences.json` and
`settings/settings.json`) are shared with other Superwhisper apps.

## Read the current state

```bash
superwhisper status          # ready, phase (idle/recording/…), workers, last dictation
superwhisper general show    # language, tone, auto-paste, login, history settings
superwhisper audio show      # microphones, sound effects, indicator, silence removal
superwhisper models show     # processing mode, offline models and their download state
superwhisper shortcuts show
superwhisper vocab show
superwhisper read            # the most recent dictation
superwhisper license status
```

## Processing mode

```bash
superwhisper models select offline        # Cohere Transcribe + S1 Mini, no internet
superwhisper models select offline_lite   # Parakeet v3, smaller download, no internet
superwhisper models select cloud          # needs internet; works on the free tier
```

An offline mode needs its models downloaded first. Check `models show`: each entry
has a `download.state` (`installed`, `missing`, `downloading`, `paused`).

- Offline needs `cohere-transcription`, `cleanup`, `vocabulary` and `voice-detection`.
- Offline Lite needs `transcription`, `vocabulary` and `voice-detection`.

```bash
superwhisper models download cohere-transcription   # also pause | cancel | verify | remove
superwhisper models unload                          # free memory now; load to warm up
```

Downloads are large (Offline is about 2.2 GB). Say so before starting one.

## Language and tone

```bash
superwhisper general set language '"en"'      # values are JSON
superwhisper general set tone '"casual"'      # casual | semi-casual | balanced | semi-formal | formal
```

Language ids are codes such as `auto`, `en`, `en-GB`, `fr`, `de`, `ja`. Each mode
supports its own list:

- **Cloud** supports all 103 languages.
- **Offline** supports `auto en en-GB fr de it es pt el nl pl zh ja ko vi ar`.
- **Offline Lite** supports `auto en en-GB bg hr cs da nl et fi fr de el hu it lv lt mt pl pt ro ru sk sl es sv uk`.

An offline mode dictates in English when the saved language is not in its list.
When you switch modes, check the language and pick one the new mode supports, or
`auto` (the desktop language).

## Other general settings

```bash
superwhisper general set autoPasteEnabled false              # false: copy to the clipboard only
superwhisper general set launchAtLogin true
superwhisper general set errorLoggingEnabled false
superwhisper general set linux.autoUnloadModels true         # unload offline models when idle…
superwhisper general set voiceModelActiveDelay 300           # …after this many seconds
superwhisper general set linux.historyEnabled true
superwhisper general set linux.saveRecordingAudio false      # keep text, drop audio (failed dictations keep theirs)
superwhisper general set linux.realtimePreview true
superwhisper general set recordingPreservationPeriod 2592000 # seconds; 0 keeps history forever
```

A shorter `recordingPreservationPeriod` deletes older history. The command
refuses and reports how many entries it would remove. Only add `--confirm` after
the user agrees to that deletion.

## Microphone, sounds and indicator

```bash
superwhisper audio select "alsa_input.…"   # a device name from `audio show`; "" is the system default
superwhisper audio favorite "alsa_input.…"
superwhisper audio ignore "alsa_input.…"
superwhisper audio set enableSoundEffects false
superwhisper audio set soundEffectVolume 0.5               # 0 to 1
superwhisper audio set soundEffectTheme '"classic"'        # simple | classic
superwhisper audio set defaultPlaybackBehavior '"duck"'    # keepPlaying | pause | duck | mute | muffle
superwhisper audio set showRecordingIndicator true
superwhisper audio set recordingIndicatorStyle '"pill"'    # pill | edgeGlow
superwhisper audio set prepareOnRecordingStart true
superwhisper audio set alwaysShowMiniRecorder false
superwhisper audio set keepMicrophoneReady true            # see below
superwhisper audio preview start                           # play a cue to test the sound
```

Silence removal (`enableSilenceRemoval`) is always on in this version.

`keepMicrophoneReady` keeps the microphone awake while Superwhisper runs, so the
first words of a dictation aren't clipped while it wakes (about half a second on
some laptops). It replaces WirePlumber 0.5's suspend hook with Superwhisper's
copy; other audio devices still sleep when idle. Changing it restarts WirePlumber,
which interrupts audio for a moment. Unset, it is on except on Omarchy, where it
is off until turned on; `audio show` reports it under `keepMicrophoneReady`.

## Keyboard shortcuts

```bash
superwhisper shortcuts set toggle "Alt+Space"     # press to start, press again to stop
superwhisper shortcuts set hold "RightSuper"      # hold to talk
superwhisper shortcuts set cancel "Escape"
superwhisper shortcuts set hold none              # disable one
superwhisper shortcuts reset                      # defaults
```

A chord is modifiers joined with `+` (`Super`, `Ctrl`, `Alt`, `Shift`) and a key,
or a single side-specific modifier such as `RightSuper`, `RightAlt` or `LeftControl`.

## Vocabulary

```bash
superwhisper vocab add "Omarchy"                   # a word or name to recognize
superwhisper vocab remove "Omarchy"
superwhisper vocab pronounce "Tauri" "Towery, Tory app"   # misheard forms that become the word
superwhisper vocab replace "super whisper" "Superwhisper"   # always rewrite this
superwhisper vocab preview "text to test"          # show what the rules would change
superwhisper vocab export ~/vocabulary.csv
superwhisper vocab import ~/vocabulary.csv
superwhisper vocab auto on                         # learn corrections automatically (auto off)
superwhisper vocab sources                         # where suggest looks (agent sessions, notes, git repos, apps, your name)
superwhisper vocab suggest                         # words you use, found in those local files, as JSON
superwhisper vocab dismiss "Hyprland"              # never suggest this word again
```

## History

```bash
superwhisper history list                          # newest 50; total counts every dictation
superwhisper history list --limit 200 --offset 50  # a page further back (limit 1-500)
superwhisper history delete TIMESTAMP --confirm
superwhisper history retry TIMESTAMP          # transcribe a failed dictation again
superwhisper history clear --confirm
```

Deleting history is permanent. Confirm with the user before any `--confirm`.

## Dictation from the command line

```bash
superwhisper record                         # toggle; start and stop are explicit
superwhisper start --device NAME            # pick a microphone for this recording
superwhisper stop
superwhisper cancel
superwhisper transcribe recording.wav       # --insert to paste the result
```

## The settings window and the Omarchy panel

`superwhisper` (or `superwhisper settings`) opens the settings window;
`superwhisper settings history` or `settings account` opens it on that tab. When
the user wants to change something themselves, point them to the settings window.
When you make a change for them, use the CLI commands on this page: they are
scriptable and print JSON to confirm. `superwhisper settings --tui` is the
terminal interface, a fallback for ssh sessions or machines without a display;
it is interactive, so do not run it yourself. On Omarchy, Superwhisper also has
a bar panel:

```bash
omarchy-shell superwhisper open
omarchy-shell superwhisper page language    # or tone, microphone; processing once an offline mode is downloaded
omarchy-shell superwhisper refresh
```

## When dictation does not work

1. `superwhisper status`. `ready: false` with a phase such as `warming` means it is
   still loading. Missing offline models show in `models show`.
2. `systemctl --user status superwhisper` and
   `journalctl --user -u superwhisper -n 100` show service errors.
3. `superwhisper doctor` checks the installation and its dependencies.
4. `systemctl --user restart superwhisper` restarts the service. Quitting from the
   panel or tray is `systemctl --user stop superwhisper`.

Stopping the service, removing models, `license remove`, and clearing history
affect the user directly. Ask before doing them.
