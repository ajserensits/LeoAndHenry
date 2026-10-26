# Claude Project Handoff

This repository contains a native SwiftUI iPhone match-three game starring the real family dogs Leo and Henry.

Before changing story, gameplay, or artwork, read:

1. `docs/STORY_BIBLE.md`
2. `docs/ART_BIBLE.md`
3. `docs/ROADMAP.md`
4. `docs/BOOSTER_SYSTEM.md`

## Non-negotiable product rules

- Leo is the older golden-brown dog who steals things and is afraid of ordinary objects.
- Henry is the younger dark-chocolate-brown dog with tan and white markings, who protects and helps Leo.
- Henry should help Leo whenever the story allows.
- The game has unlimited lives and no ads, purchases, required account, or tracking.
- Normal match pieces are all circular. Special states and power-ups follow the dust-overlay pattern: preserve the Leo face and identifying background, keep the center clear, and communicate the state with a translucent rim, perimeter detail, or compact edge badge. Never let an overlay dominate the underlying piece. Only a true non-matchable blocker may fully cover its cell.
- Player progression remains sequential and saved on-device.
- Starting-booster inventory and completed Booster Basket events are also saved on-device. Do not make the levels 3 and 7 reward event repeatable without an explicit economy decision.
- Any level-unlock/testing interface must be compiled only under `#if DEBUG` and must not corrupt genuine saved progress.
- Preserve portrait and both landscape orientations.

## Current project

- Open `HenrysGardenChase.xcodeproj`.
- App source is under `SproutAndSmiles/`.
- Current gameplay model is `SproutAndSmiles/GameModel.swift`.
- Main gameplay UI is `SproutAndSmiles/ContentView.swift`.
- Chapter map is `SproutAndSmiles/ChapterMapView.swift`.
- Approved raster artwork is under `SproutAndSmiles/Artwork/`.
- `project.yml` is the source configuration for XcodeGen, but verify generated project compatibility before replacing the committed project file.

The installed Xcode must be able to read object version 56. Some newer XcodeGen versions emit object version 77 even when generating on this machine. If regeneration is necessary, inspect `HenrysGardenChase.xcodeproj/project.pbxproj` before committing and ensure both `objectVersion` and `preferredProjectObjectVersion` remain compatible with the installed Xcode.

## Build verification

Use a disposable DerivedData directory:

```bash
xcodebuild \
  -project HenrysGardenChase.xcodeproj \
  -scheme HenrysGardenChase \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -configuration Debug \
  -derivedDataPath /tmp/LeoHenryBuild \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Warnings about unavailable Simulator services do not invalidate a successful generic-device build. The command must still exit with status 0.

## Artwork workflow

- Use the existing approved assets as style and identity references.
- Do not invent different coat colors, markings, ear shapes, or body proportions.
- Keep generated text out of artwork; render copy in SwiftUI.
- Add new final PNGs to the app target's Resources build phase and confirm they appear in the built `.app` bundle.
- Prefer new filenames until an asset is approved.
- Never commit private tokens, signing certificates, provisioning profiles, DerivedData, or unapproved raw family photographs.
- When handing off an image, include the generation prompt, intended crop, dimensions, and exact consuming screen.

## Change discipline

- Preserve existing behavior unless the task explicitly changes it.
- Keep commits focused and describe player-visible effects.
- Build after Swift or project-file changes.
- Call out which ideas are implemented versus only planned; do not represent story documentation as playable content.
