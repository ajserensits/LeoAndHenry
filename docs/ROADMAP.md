# Development Roadmap

## Current playable foundation

- Native SwiftUI iPhone app targeting iOS 17.
- Eight-by-eight match-three board with tap and swipe controls.
- Cascades, move-limited collection goals, and layered dust-clearing goals.
- Row and column rockets from four-piece matches.
- Rainbow paw from a straight five-piece match.
- Garden bomb from an L- or T-shaped match.
- Unlimited lives, shuffle, water, and hint helpers.
- Seven ten-level chapter maps with continuous saved progression.
- Portrait and landscape layouts.
- Chapter-specific garden and vacuum-hallway backgrounds with character-driven map styling.

Chapter One's ten levels mainly vary the target expression, quantity, and move count. Chapter Two's first playable slice introduces one- and two-layer dust objectives. The remaining story events and objective varieties below remain future implementation work.

## Gameplay variety plan

| Objective | Player action | Possible story use |
|---|---|---|
| Collect | Match a specified Leo expression or story item | Follow Leo's trail or gather comfort objects |
| Clear blockers | Match through layered obstacles to remove them | Vacuum dust is implemented; Chapter Six adds cans (one or two rattles) and breeze-drifting bags cleared by matches on or beside them; garden clutter remains planned |
| Wake sleeping Leo | Match on or beside sleeping Leo pieces to trigger Henry's bark | Implemented in Chapter Two levels 6 and 9 |
| Rescue route | Match on or beside the highlighted next pawstep to move Henry toward Leo | Implemented throughout Chapter Three |
| Drop items | Clear space beneath an item until it reaches the bottom | Return a toy, biscuit, bug, bowl, or parcel |
| Rescue Leo | Clear or match around Leo's hiding place | Help Leo come out from under the bed |
| Guide Henry | Open a connected route across the board | Chapter Five uses sequential quiet leaves while a harmless mower marker loops around the board edge |
| Spread comfort | Match on or beside the blanket; each touching group of cleared cells becomes cozy | Implemented in Chapter Four (levels 2, 3, 5, 7, 9, 10) |
| Find clues | Reveal hidden clue tiles under grass, leaves, or furniture | Implemented in Chapter Seven with one- and two-layer leafy patches revealing Mom's slipper, keys, and familiar pawprints |
| Protect | Clear approaching nuisance tiles before they reach a protected area | Delivery knock, storm puddles, or noisy objects |
| Multi-goal | Combine two simple goals in one level | Recover the item and help Leo feel safe |

Avoid real-time timers as the default difficulty tool. Difficulty should come from board layout, move planning, layered goals, and satisfying power-up choices.

## Development access versus player progression

The release experience should require the player to complete levels in order. Development builds need a separate testing path so new mechanics can be reviewed without replaying the entire story.

The app now includes a `#if DEBUG` developer console that can preview any current level without changing genuine progress, unlock all current levels, mark progress through the selected level, and reset progress. As objective and chapter systems are added, extend it to:

- Open any level or chapter without altering the player's genuine saved progress. *(Current levels implemented.)*
- Preview every objective and obstacle type.
- Reset or seed progress deliberately. *(Reset and unlock-all implemented.)*
- Grant a chosen power-up for testing.
- Display board and save-state diagnostics.

Never expose this menu in Release or TestFlight builds intended for normal play.

## Recommended milestone order

### Milestone 1: Chapter system and first variety *(in progress)*

- Convert three existing levels into three genuinely different objectives.
- Add one layered blocker, one drop-item goal, and one route or rescue goal.
- Add short pre-level and post-level story cards.
- Add the DEBUG-only level picker. *(Implemented for every current chapter.)*
- Preserve existing save data through a versioned save model.

### Milestone 2: Fear-event mechanics

- Vacuum behavior and dust blockers. *(Layered dust implemented; active vacuum behavior remains.)*
- Under-the-bed rescue board. *(Sequential rescue route implemented; story panels and props remain.)*
- Thunderstorm comfort-spreading mechanic. *(Implemented with cosmetic thunder every few moves; a slow glow that Reduce Motion disables.)*
- Lawnmower route hazard. *(Implemented in Chapter Five with quiet-route levels and a moving, non-punitive mower loop.)*
- Bags and cans as movable or layered blockers. *(Implemented in Chapter Six: layered cans, bags that drift one square on each breeze, never punitive.)*

### Milestone 3: Story systems

- Reusable story-panel presentation.
- Chapter and scene data separated from gameplay code.
- Per-chapter art, palette, music, and map metadata.
- “Find Mom” clue search. *(Implemented in Chapter Seven; reusable story panels remain planned.)*
- Pool day, delivery, and birthday finale scenes.

### Milestone 4: Polish and accessibility

- VoiceOver labels and logical focus order.
- Reduce Motion alternatives.
- Color-independent piece identification.
- Adjustable sound and music levels.
- Haptic settings.
- Larger-text testing for menus and story cards.
- Performance and memory testing on an older supported iPhone.

### Milestone 5: Distribution

- Final app icon and launch presentation.
- Privacy manifest and App Store metadata.
- TestFlight build and family playtesting.
- Difficulty tuning from actual completion data stored locally and shared voluntarily.

## Technical direction

- Keep gameplay rules separate from SwiftUI presentation.
- Move level definitions from hard-coded initializers toward Codable data.
- Version persistent progress before the level model changes substantially.
- Give each objective and obstacle deterministic unit tests.
- Keep all normal content playable offline.
- Do not introduce ads, consumable lives, tracking, or required accounts.
