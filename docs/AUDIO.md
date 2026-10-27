# Audio

All music and sound effects are synthesized in code by `SproutAndSmiles/GameAudio.swift`, so there are no audio files, licenses, or download size. The single speaker button (`GameModel.soundOn`) turns music, sound effects, and haptics on or off together. The ambient audio session respects the silent switch and mixes with the player's own music.

## Music

One looping theme per chapter plus the yard. `ContentView` picks the theme: the yard while it is open, otherwise the chapter shown on the map, otherwise the chapter of the level being played. Changing themes crossfades in about half a second.

| # | Chapter | Theme | Feel |
|---|---|---|---|
| 1 | The Bug in the Beans | Garden Trail | The original bright plucked garden loop |
| 2 | The Vacuum Awakens | Cleaning Day Scurry | Quick marimba scurry |
| 3 | Under the Bed | Under-the-Bed Music Box | Gentle minor music box |
| 4 | Thunder over the Tomatoes | Blanket Lullaby | Slow, soft flute lullaby |
| 5 | The Lawnmower Loop | Lawn March | Jaunty march with bass |
| 6 | Bags, Cans, and Courage | Brave Breeze | Brave steel-drum melody |
| 7 | Where Is Mom? | Looking for Mom | Wistful flute that ends hopeful |
| 8 | Pool Day | Pool Day Bounce | Bouncy, syncopated steel drum |
| 9 | Special Delivery | Tiptoe Delivery | Tiptoeing pizzicato |
| 10 | The Birthday Peanut-Butter Pad | Birthday Party | Bright party bells (original, not "Happy Birthday") |
| — | Leo & Henry's Yard | Our Yard | Cozy, homey flute |

Each `MusicTheme` is a list of melody notes (`.` rest, `-` hold), one chord per four steps, a lead voice, and optional arpeggio, bass, and pad levels. `gain` evens out loudness so every theme sits near the garden loop's level. To add or change a theme, edit `MusicTheme.all`; the index matches `Chapter.id`, and the last entry is the yard.

## Sound effects

| Effect | When |
|---|---|
| select | Picking the first piece of a swap |
| nope | A swap that makes no match |
| pop | Each match; each cascade step pops a little higher |
| powerUpMade | A match that creates a rocket, garden bomb, or rainbow paw |
| rocket / gardenBomb / rainbowPaw | Activating a power-up |
| water / shuffle | The water and shuffle helpers |
| thunder / knock / party | Chapter 4 thunder, Chapter 9 door knocks, Chapter 10 party commotion (kept soft) |
| win | Completing a level |
| yardBuild / yardStyle | Fixing up a yard spot and switching its style |

## Previewing

`GameAudio.swift` also compiles for macOS, so the themes and effects can be rendered to WAV files for listening and level checks without running the app: compile it with `swiftc` together with a small `main.swift` that calls `MusicTheme.all[i].render(format:)` and `SoundEffects.render(_:format:)`, then write the buffers with `AVAudioFile`.
