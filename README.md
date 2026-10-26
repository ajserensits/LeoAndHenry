# Henry & Leo: The Great Garden Chase

A private, native iPhone match-three garden game starring Leo and Henry. Mischievous Leo steals Henry's toy, snack, meal, or treasured object, and protective little brother Henry follows the clues while helping Leo through the things that frighten him.

## What is in the playable build

- Six ten-level chapters with chapter-specific storybook maps
- Chapter Two's first new objective: one- and two-layer vacuum dust tiles
- Sleeping-Leo objectives where nearby matches trigger Henry's wake-up bark
- Under-the-bed rescue routes that move Henry toward Leo one pawstep at a time
- Thunderstorm comfort levels where matches beside the blanket spread it across the board
- Lawnmower-loop levels where Henry leads Leo along a glowing quiet route while the mower circles safely away
- Porch-noise levels where matches beside rattling cans and drifting plastic bags let Henry hush them one at a time
- Original title artwork based on the supplied photos of Leo and Henry
- Distinct illustrated Leo expression pieces and a Henry map portrait
- Portrait and landscape play, including a full-height centered landscape board
- Match-four, match-five, and L-shaped-match power-ups
- Unlimited lives and free extra moves
- Tap-to-swap and swipe-to-swap controls
- Cascades, goals, hints, shuffling, and a watering-can booster
- A garden that fills with flowers and a cat as levels are completed
- On-device progress saving
- No ads, accounts, timers, tracking, or purchases

## Project guides

- [Story Bible](docs/STORY_BIBLE.md) — character canon, emotional rules, and the proposed ten-part story arc
- [Art Bible](docs/ART_BIBLE.md) — visual language, asset specifications, naming, and the artwork queue
- [Development Roadmap](docs/ROADMAP.md) — gameplay varieties and the path from prototype to complete chapters
- [Claude Handoff](CLAUDE.md) — repository-specific instructions for anyone continuing the implementation or artwork

Chapter One contains the original collection levels. Chapter Two, **The Vacuum Awakens**, adds a hallway setting, layered dust-clearing levels, and sleeping-Leo wake-up levels. Chapter Three, **Under the Bed**, adds sequential rescue routes that guide Henry to Leo. Chapter Four, **Thunder over the Tomatoes**, adds a stormy sunroom and comfort-spreading blanket levels. Chapter Five, **The Lawnmower Loop**, adds a sunny backyard, moving mower marker, and quiet-route levels where Henry leads Leo safely home. Chapter Six, **Bags, Cans, and Courage**, adds a breezy porch where Henry quiets one- and two-rattle cans and bags that drift on the wind without ever undoing progress. Drop-item, clue, protection, and story-card systems remain planned work.

## Run it on an iPhone

1. Open `HenrysGardenChase.xcodeproj` in Xcode 15.4 or newer.
2. Select the **HenrysGardenChase** project, then the **HenrysGardenChase** target.
3. Under **Signing & Capabilities**, select your Apple development team. Change the bundle identifier if Xcode says it is already taken.
4. Connect the iPhone, select it as the run destination, and press **Run**.
5. The first time, the iPhone may ask you to enable Developer Mode or trust the developer certificate.

A free Apple ID is enough for personal device testing, although a free signing installation may need to be refreshed periodically. TestFlight distribution requires an Apple Developer Program membership.

## Notes

The project targets iOS 17 and supports portrait plus both landscape orientations. Artwork is original and based on family-provided photographs of Leo and Henry.
