# Henry & Leo: The Great Garden Chase

A private, native iPhone match-three garden game starring Leo and Henry. Mischievous Leo steals Henry's toy, snack, meal, or treasured object, and protective little brother Henry follows the clues while helping Leo through the things that frighten him.

## What is in this first playable build

- A ten-level opening chapter with a storybook level map
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

The current ten levels are a polished gameplay prototype for Chapter One. The broader fear-and-rescue story and the distinct objective types in the documents above are planned work, not all implemented yet.

## Run it on an iPhone

1. Open `HenrysGardenChase.xcodeproj` in Xcode 15.4 or newer.
2. Select the **HenrysGardenChase** project, then the **HenrysGardenChase** target.
3. Under **Signing & Capabilities**, select your Apple development team. Change the bundle identifier if Xcode says it is already taken.
4. Connect the iPhone, select it as the run destination, and press **Run**.
5. The first time, the iPhone may ask you to enable Developer Mode or trust the developer certificate.

A free Apple ID is enough for personal device testing, although a free signing installation may need to be refreshed periodically. TestFlight distribution requires an Apple Developer Program membership.

## Notes

The project targets iOS 17 and supports portrait plus both landscape orientations. Artwork is original and based on family-provided photographs of Leo and Henry.
