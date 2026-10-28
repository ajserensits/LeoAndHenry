# Game Content Guide

Chapters and levels are data files rather than Swift source. The app loads them from `SproutAndSmiles/GameContent/` when it starts, so adding story content normally does not require editing `GameModel.swift`.

## File layout

- `chapters.json` is the ordered chapter manifest.
- `chapter-01.json` through `chapter-10.json` contain the chapter presentation and ordered level definitions.
- `GameContent.swift` decodes and validates those files, then creates the runtime `Chapter` and `Level` values used by the game.

The order of filenames in `chapters.json` controls chapter order. The order of levels inside each chapter file controls map and gameplay order.

## Permanent IDs and saved progress

Every chapter and level has an `id`. Treat these IDs as permanent save-game keys:

- Never rename or reuse an existing ID after a build has reached a player.
- Moving an existing level within a chapter is safe as long as its ID stays the same.
- Inserting a new level is safe and does not make completed levels look incomplete.
- Do not renumber old IDs to make a newly inserted level fit. Give the new level a fresh immutable ID, such as `chapter-02-level-dusty-detour`.

The app automatically migrates the original number-based saves to permanent level IDs the first time this version runs. It preserves completed levels, the highest unlocked point, the current level, first-win yard treats, and claimed Booster Basket rewards. The old number-based values are also maintained for compatibility with older builds.

## Add a level to an existing chapter

1. Open the appropriate `chapter-XX.json` file.
2. Add a new object to its `levels` array at the desired play position.
3. Give it a new permanent ID.
4. Supply the required fields and any mechanic fields needed by the level.
5. Regenerate the Xcode project and run the verification steps below.

Minimal collection level:

```json
{
  "id": "chapter-01-level-sunflower-snack",
  "goal": "tomato",
  "amount": 24,
  "moves": 30,
  "title": "The Sunflower Snack",
  "stolenItem": "sunflower biscuit",
  "clue": "Henry spots a crumb beside the tallest flower."
}
```

Allowed `goal` values are `tomato`, `carrot`, `onion`, `pepper`, `eggplant`, and `pea`. These are historical internal names for the six Leo expressions.

## Add a chapter

1. Copy an existing chapter file to a new filename such as `chapter-11.json`.
2. Give the chapter a new permanent ID, title, subtitle, background asset name, and SF Symbol name.
3. Add its levels with new permanent IDs.
4. Add the filename to the end of the `chapters` array in `chapters.json`.
5. Add any referenced artwork to the app target.
6. Regenerate the Xcode project and verify the build.

Chapter shape:

```json
{
  "id": "chapter-11-example",
  "title": "Chapter Title",
  "subtitle": "One short map description.",
  "backgroundName": "chapter-eleven-background",
  "symbol": "leaf.fill",
  "levels": []
}
```

There is no ten-level requirement in the loader. A chapter may contain more or fewer levels, although map layout, difficulty pacing, story beats, and Booster Basket placement should be playtested when its length changes. The Booster Basket currently appears before the third and seventh positions of each chapter.

## Optional level mechanics

Omitted optional values use the same defaults as before this conversion.

| Fields | Mechanic |
| --- | --- |
| `dustCells`, `dustDepth` | Layered vacuum dust |
| `sleepingCells` | Sleeping Leo pieces awakened by Henry |
| `rescueSteps` | Under-the-bed rescue route |
| `comfortCells`, `thunderEvery` | Blanket spreading and thunder |
| `quietRouteSteps`, `mowerEvery` | Quiet route and moving mower |
| `canCells`, `canDepth`, `bagCells`, `breezeEvery` | Porch cans and drifting bags |
| `clueCells`, `clueDepth` | Hidden familiar clues |
| `splashCount`, `splashEvery` | Pool splashes and towel protection |
| `parcelCount`, `knockEvery`, `parcelIsPad` | Parcel or peanut-butter-pad delivery |
| `partyEvery` | Birthday party event timing |
| `potCells` | Pots broken by nearby matches |
| `crateCells`, `crateDepth` | Layered crates broken by nearby matches |
| `stoneCells`, `stoneDepth` | Stones that require power-ups |
| `beetleCount` | Moving beetle blockers |
| `gooCells` | Spreading goo |

Use `amount: 0` when a level should have only its special objective. A positive `amount` combines collecting the selected Leo expression with the special objective or objectives.

## Verification

After adding a new JSON file, regenerate the committed Xcode project so it is included in the app bundle:

```bash
xcodegen generate
```

Then make a generic-device build without signing:

```bash
xcodebuild \
  -project HenrysGardenChase.xcodeproj \
  -scheme HenrysGardenChase \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/LeoHenryContentBuild \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The loader stops with a clear error during development if a content file is missing, malformed, empty, contains duplicate IDs, or gives a level invalid moves or amount values. Gameplay balance still requires playtesting and the balance tools described in `BLOCKERS.md`.
