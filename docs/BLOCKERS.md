# Blockers, Goo, and Difficulty

*(Implemented.)* From Chapter Two onward, levels add obstacles that are not Leo pieces. They ramp up chapter by chapter, and running out of moves is now a real loss (lives stay unlimited).

## Blockers

Painted art lives in `SproutAndSmiles/Artwork/Blockers/` (256×256 transparent PNGs, generated with Codex; prompts in `ArtworkSource/prompts/blockers/`). Blockers are true non-matchable obstacles, so they may cover their whole cell. Pieces above a blocker don't fall past it; each gap refills from above.

| Blocker | Moves? | How to clear | First chapter |
| --- | --- | --- | --- |
| Flowerpot | No | One match beside it, or any power-up | 2 |
| Toy crate | No | Two (some late levels three) matches beside it; a number badge shows hits left and art cracks on the last hit | 3 |
| Garden stone | No | **Power-ups only** (rocket, bomb, rainbow paw). A berry burst badge marks it. Late stones take two hits | 5 |
| Beetle | Yes, one step after every move | One match beside it, or any power-up | 6 |

## Spreading goo

- Mud in Chapter Seven onward; pink birthday frosting in Chapter Ten.
- Gooed Leos stay in place and can't be swapped. They can still be part of a match.
- A match on or beside a gooed Leo cleans it off.
- After any move that cleans no goo, it spreads onto one neighboring Leo, up to 18 cells.
- Following the overlay rule, goo is a translucent rim with drips. Leo's face and background stay visible.
- No blockers or goo appear in parcel and peanut-butter pad levels, or on any cell an objective uses.

## Failing and earning moves

- Running out of moves shows the out-of-moves card. **Try again** is always free. The old "+10 moves on the house" is gone.
- **Henry's second wind:** once per attempt, if the goal is at least 75% done, the player can take +5 moves.
- **Treat bags:** a few refilled pieces (2.5% each, at most two on the board) carry a "+2" edge badge. Popping one adds two moves.
- The watering can is limited to **3 uses per attempt** (it was unlimited), so it can't trivialize the new difficulty. Change `GameModel.watersPerLevel` to tune it.
- If blockers leave no legal swap, Henry reshuffles the board for free.

## Move calibration

Move counts come from a headless bot (`tools/balance/`).

- The bot is greedy. It prefers power-ups and matches that touch objective cells, and it never uses water or second wind.
- Each level's moves are set to the bot's moves-needed at a percentile that drops by chapter, times 1.15, plus 3, clamped to 10–50:
  - Chapters 1–2 use P90.
  - Chapters 3–6 use P75.
  - Chapters 7–10 use P60.
- At the shipped values, the bot wins about 99% in Chapter One, about 90% mid-game and about 70–85% in Chapters Nine and Ten. The lowest are levels 85 and 82, at 60–65%.

To re-run after changing levels:

```bash
tools/balance/prep.sh "$PWD"   # builds tools/balance/bot against the current GameModel
tools/balance/bot 40 19        # 40 trials of level 20 (0-based index) with 120 moves
tools/balance/bot 40 19 real   # same, with the level's real move count; prints win%
```

The bot uses an in-memory defaults stand-in, so it never touches saved progress.
