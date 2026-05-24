# Dream Catcher

**By Sharin Khander**

A native iOS dream journal for the fragile moment between sleep and waking.

## Elevator pitch

You wake up holding a dream — and within minutes it's gone. **Dream Catcher** is built for that half-awake moment: tap the mic, speak a fragment, and see your words transcribed before they fade. Over time, it organizes what you remember into narratives, recurring symbols, and a visual timeline of your inner life. Soft, private, and made for people who want to remember what their mind was trying to say.

## Core Features

### Wake-Up Capture (Bedside Mode)
- One-tap voice recording with live transcription
- Designed for groggy mornings — speak before you forget

### Dream Reconstruction
- Organizes fragments into a coherent narrative
- Layered reflection: Emotional Mirror, Modern Psychology, Jungian/Symbolic, Narrative Reflection

### Pattern Engine
- Recurring symbols with personal meaning
- Dream personas (The Guide, The Pursuer, The Watcher…)
- Apple Health sleep correlation

### Cosmic Timeline
- Floating dream orbs color-coded by emotion
- Recurring symbols connected by glowing threads

### Lock Screen Widget
- One tap to open capture from the home or lock screen

## Open in Xcode

```bash
open DreamCatcher.xcodeproj
```

Select the **DreamCatcher** scheme, choose an iPhone simulator or device, and run (⌘R).

Set your **Development Team** in Signing & Capabilities for both targets:
- DreamCatcher
- DreamCatcherWidgetExtension

## Architecture

```
DreamCatcher/
├── App/              Entry point, SwiftData container
├── Models/           Dream, Fragment, Symbol, Persona, LifeEntry
├── Views/
│   ├── Capture/      BedsideCaptureView
│   ├── Dream/        Detail + interpretation layers
│   ├── Timeline/     Cosmic orb visualization
│   ├── Patterns/     Insights + symbol memory
│   └── Reflect/      Reflective dialogue
├── Services/
│   ├── SpeechCaptureService
│   ├── DreamReconstructionService
│   ├── PatternEngine
│   ├── HealthKitService
│   └── AmbientAudioService
└── Intents/          App Shortcuts (optional)
```

## Requirements

- iOS 17+
- Xcode 15+
- Microphone + Speech Recognition permissions
- Apple Health (optional, for sleep correlation)
