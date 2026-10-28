# Henry & Leo: The Great Garden Chase

A private, native iPhone match-three garden game starring Leo and Henry. Mischievous Leo steals Henry's toy, snack, meal, or treasured object, and protective little brother Henry follows the clues while helping Leo through the things that frighten him.

## What is in the playable build

- Ten ten-level chapters (100 levels) with chapter-specific storybook maps
- Chapter Two's first new objective: one- and two-layer vacuum dust tiles
- Sleeping-Leo objectives where nearby matches trigger Henry's wake-up bark
- Under-the-bed rescue routes that move Henry toward Leo one pawstep at a time
- Thunderstorm comfort levels where matches beside the blanket spread it across the board
- Lawnmower-loop levels where Henry leads Leo along a glowing quiet route while the mower circles safely away
- Porch-noise levels where matches beside rattling cans and drifting plastic bags let Henry hush them one at a time
- Hidden-clue levels where Henry uncovers Mom's slipper, keys, and familiar pawprints beneath leafy patches
- Pool-day levels where splashes creep toward Leo's towel and Henry nudges back any that get too close
- Special-delivery levels where clearing beneath parcels carries them safely down to the doormat
- A birthday finale with peanut-butter pads to bring down to Mom, two-goal "birthday goals" levels, and a closing story card after level 100
- Original title artwork based on the supplied photos of Leo and Henry
- Distinct illustrated Leo expression pieces and a Henry map portrait
- Portrait and landscape play, including a full-height centered landscape board
- Match-four, match-five, and L-shaped-match power-ups
- Henry's Booster Basket before levels 3 and 7 of every chapter, with falling rockets, garden bombs, and rainbow paws to catch
- A persistent starting-booster inventory and pre-level loadout where saved boosters can be brought onto any board
- Unlimited lives and free extra moves
- Tap-to-swap and swipe-to-swap controls
- Cascades, goals, hints, shuffling, and a watering-can booster
- A garden that fills with flowers and a cat as levels are completed
- On-device progress saving
- No ads, accounts, timers, tracking, or purchases

## Project guides

- [Game Content](docs/GAME_CONTENT.md) — JSON-backed chapters and levels, permanent save IDs, and safe expansion steps
- [Story Bible](docs/STORY_BIBLE.md) — character canon, emotional rules, and the proposed ten-part story arc
- [Art Bible](docs/ART_BIBLE.md) — visual language, asset specifications, naming, and the artwork queue
- [Development Roadmap](docs/ROADMAP.md) — gameplay varieties and the path from prototype to complete chapters
- [Booster System](docs/BOOSTER_SYSTEM.md) — basket-game rules, persistent inventory, loadout behavior, and developer testing notes
- [Claude Handoff](CLAUDE.md) — repository-specific instructions for anyone continuing the implementation or artwork

Chapter One contains the original collection levels. Chapter Two, **The Vacuum Awakens**, adds layered dust and sleeping-Leo goals. Chapter Three, **Under the Bed**, adds rescue routes. Chapter Four, **Thunder over the Tomatoes**, adds comfort spreading. Chapter Five, **The Lawnmower Loop**, adds quiet routes and a moving mower. Chapter Six, **Bags, Cans, and Courage**, adds layered cans and drifting bags. Chapter Seven, **Where Is Mom?**, adds hidden clues. Chapter Eight, **Pool Day**, adds creeping splashes and towel protection. Chapter Nine, **Special Delivery**, adds true drop-item levels where parcels descend as spaces beneath them are cleared, plus gentle door-knock moments that never undo progress. Chapter Ten, **The Birthday Peanut-Butter Pad**, revisits every earlier goal with a party twist, sends peanut-butter pads down to Mom, adds two-goal levels with per-goal progress chips, and ends with a closing card of the brothers sharing the pad. Reusable per-level story cards remain planned work.

## Run it on an iPhone

1. Open `HenrysGardenChase.xcodeproj` in Xcode 15.4 or newer.
2. Select the **HenrysGardenChase** project, then the **HenrysGardenChase** target.
3. Under **Signing & Capabilities**, select your Apple development team. Change the bundle identifier if Xcode says it is already taken.
4. Connect the iPhone, select it as the run destination, and press **Run**.
5. The first time, the iPhone may ask you to enable Developer Mode or trust the developer certificate.

A free Apple ID is enough for personal device testing, although a free signing installation may need to be refreshed periodically. TestFlight distribution requires an Apple Developer Program membership.

## Notes

The project targets iOS 17 and supports portrait plus both landscape orientations. Chapter and level definitions live in editable JSON files under `SproutAndSmiles/GameContent/`, with permanent IDs that preserve saved progress when content is expanded or reordered. Artwork is original and based on family-provided photographs of Leo and Henry.
