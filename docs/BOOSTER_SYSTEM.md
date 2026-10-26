# Starting Boosters and Henry's Booster Basket

This document describes the implemented starting-booster economy and its pre-level mini-game. These rewards are deliberately generous, local, and non-purchasable: they add playful choices without recreating the lives, timers, or monetization pressure this game is meant to avoid.

## Player flow

1. The first time the player opens local level 3 or level 7 of any chapter, **Henry's Booster Basket** appears before the level.
2. For ten seconds, the player drags horizontally anywhere on the screen to move Henry and his basket.
3. Falling rockets, garden bombs, and rainbow paws can be caught. Henry can carry at most three rewards per basket game.
4. Socks, tennis balls, and leaves are harmless silly drops. They make Henry wobble, but never remove a reward or otherwise punish the player.
5. Caught boosters are added to persistent inventory, and the basket event is marked claimed.
6. The normal pre-level loadout opens. The player may select up to one of each available booster, or save everything for later.
7. Selected boosters are consumed when the level starts and are placed on random board pieces, ready to use with the game's normal power-up rules.

All standard levels show the loadout, including levels that do not have a basket event. A player with no inventory can immediately choose **Play Without Boosters**.

## Schedule and rewards

- Basket events occur at chapter-local levels 3 and 7.
- With ten chapters, the current game contains twenty one-time basket events.
- Each event lasts ten seconds and awards at most three boosters.
- Current drop weighting is intentionally friendly:
  - Rocket: 38 percent
  - Garden bomb: 22 percent
  - Rainbow paw: 12 percent
  - Harmless silly object: 28 percent
- A caught rocket becomes either a row rocket or a column rocket when placed on the board.
- A basket event is claimed when its timer finishes, even if the player catches nothing. This prevents the reward sequence from becoming an unlimited farming loop.

These values are first-pass tuning constants, not an economy contract. Adjust them from playtesting, but preserve the no-purchase and no-punishment rules.

## Persistence

The system currently uses `UserDefaults`, consistent with the rest of the game's local progress. The keys are:

- `boosterInventory.rocket`
- `boosterInventory.gardenBomb`
- `boosterInventory.rainbowPaw`
- `boosterBasket.claimedLevels`

Inventory is saved when rewards are granted or boosters are consumed. Claimed events are stored as sorted global level indexes. Resetting progress in the DEBUG developer console also clears booster inventory and claimed basket events.

If progression later moves to a versioned `Codable` save file, migrate all four values rather than silently resetting the player's inventory.

## Developer testing

The DEBUG-only developer console includes **Grant 10 of Every Booster**. This allows loadout and placement testing without replaying basket events. Developer level preview continues to open a board directly and does not consume inventory or claim a basket event.

Useful checks before release:

- A first visit to every chapter's levels 3 and 7 opens the basket exactly once.
- Reopening or replaying one of those levels goes directly to the loadout.
- Caught rewards survive an app relaunch.
- Selected rewards decrement once and appear as ordinary, usable special pieces.
- Unselected rewards remain in inventory.
- Reset Progress clears inventory and makes the basket events eligible again.
- The developer grant action is absent from Release builds.

## Accessibility and presentation

- Dragging anywhere horizontally controls Henry, so the player does not need to keep a finger precisely on a small target.
- Reduce Motion slows falling objects and removes the silly-object wobble.
- The reward slots provide a visible count of catches during play.
- Booster loadout cards state inventory counts and selection state to accessibility technologies.
- The mini-game uses the current chapter backdrop so it feels like a story beat rather than a detached utility screen.

Future polish may add dedicated catch sounds, a short reward recap, improved VoiceOver play controls, and original basket artwork. Any audio must obey the existing sound setting, and any new motion needs a Reduce Motion alternative.
