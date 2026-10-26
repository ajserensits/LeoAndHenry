# Art Production Pack

Ready-to-use image prompts and specifications for the Art Bible's priority queue. Everything here is **planned artwork**. None of these images exist yet, and most of the screens that will use them (story panels, blockers, new chapters) are not implemented yet either. See `ROADMAP.md`.

## Workflow

1. Generate with an image model that accepts reference images (for example ChatGPT image generation). Always attach the reference files listed for the asset.
2. Save raw outputs to `ArtworkSource/candidates/` (not in the app bundle).
3. Resize or crop to the final export size, then run:
   ```bash
   python3 -I ArtworkSource/tools/check_asset.py ArtworkSource/candidates/<file>.png
   ```
4. Lay the matching template from `ArtworkSource/templates/` over the image and confirm the safe zones hold. Regenerate templates with `python3 -I ArtworkSource/tools/make_templates.py`.
5. Walk the Art Bible review checklist. Pay special attention to the coat, ears, and proportions of each dog.
6. Once approved, move the file into `SproutAndSmiles/Artwork/`, add it to the app target's Resources build phase, build, and confirm it appears in the built `.app`.

## Shared blocks

Paste the **style block** first in every prompt, followed by the identity block for each dog that appears.

**Style block**
> Premium storybook illustration with a soft, painterly 3D rendering style, like a high-end animated film still. Warm golden-hour lighting, rich saturated colors, soft fur detail, gentle depth of field. Cozy, funny, affectionate mood, never threatening. Small dogs in a world that feels large from their eye level. Match the rendering style, color palette, and lighting of the attached reference images exactly. No text, letters, numbers, logos, signatures, or watermarks anywhere in the image.

**Leo identity block** (references: `leo-henry-garden-chase.png`, `leo-expression-sheet.png`)
> Leo: a small, very round, extremely fluffy dog with a long golden-ginger coat, a cream muzzle and chest, full cheek fur, a short muzzle with a small dark-brown nose, dark round eyes, and long feathered floppy ears. His silhouette is wide and round, clearly rounder and wider than Henry's. He must look exactly like the golden dog in the reference images.

**Henry identity block** (references: `henry-map-marker.png`, `leo-henry-garden-chase.png`)
> Henry: a small, alert, long-coated dog whose coat is predominantly a rich dark chocolate brown (not black), with a white-and-cream muzzle, chest ruff, and paws, tan eyebrow spots and cheek markings, large expressive brown eyes, a small brownish nose, and tall pointed upright ears with fringed fur. He is slimmer, more upright, and more angular than Leo. He must look exactly like the chocolate-brown dog in the reference images, with the same warm dark-brown coat shade.

**Common rejects:** a third dog, extra limbs or tails, Henry with floppy ears, Henry rendered jet-black instead of chocolate brown, Leo with pointed ears, coat colors swapped or blended, any baked-in text, a scary or realistic menacing object, or characters inside the board zone of a background.

## Format specs

| Kind | Generate at | Final export | Template | Transparency |
|---|---|---|---|---|
| Chapter background | 1536×1024 | 1672×941 (scale to 1672 wide, center-crop height) | `template-chapter-background-1672x941.png` | No |
| Story panel | 1536×1024 | 1536×1024 | `template-story-panel-1536x1024.png` | No |
| Obstacle / blocker | 1024×1024 | 512×512 | `template-obstacle-512.png` | Yes |
| Map marker | 1024×1024 | 512×512 | `template-map-marker-512.png` | No |
| App icon | 1024×1024 | 1024×1024 | `template-app-icon-1024.png` | No (no alpha) |

**Background crops:** in landscape the board covers about the central 55%. In portrait, only a central strip about 26% wide is visible behind the board, so that strip must look good alone. Keep the top-right corner low in contrast for the pause button.

**Story-panel crops:** landscape shows the full panel. Portrait is planned to show a centered square, so both dogs and the scary object must fit inside the central 1024×1024. Keep the bottom 20% simple (floor, grass, or rug) because SwiftUI will render the caption there.

> **Chapter numbering assumption:** these filenames treat each story-arc beat as its own chapter (Beat 2 → `chapter-02`). The current game has all ten levels in one Chapter One garden. Rename before integration if the structure ends up different.

---

## Wave 1: vertical slice (Beats 2 and 3)

### 1. `obstacle-vacuum.png`
- **Purpose:** the vacuum as a board hazard icon for the Beat 2 fear event (Milestone 2, "Vacuum behavior").
- **Consuming screen:** gameplay board, as an overlay on cells (planned; not implemented).
- **Crop:** whole object centered, about 84% of the frame, viewed from a slightly low, dog's-eye angle.
- **References:** `chapter-one-garden.png` (for style only).
- **Prompt:** *[Style block]* A single upright household vacuum cleaner shown as a game icon on a fully transparent background. A chunky, rounded, toy-like design in soft sage green and cream, with a coiled cord and a gently glowing power light. It looks big and noisy but harmless and a little silly, with no face. Clean silhouette, readable at very small sizes, soft rim lighting, no floor, no shadow outside the object.

### 2. `obstacle-dust-layer-2.png` and `obstacle-dust-layer-1.png`
- **Purpose:** a two-layer blocker. Each adjacent match removes one layer (ROADMAP "Clear blockers").
- **Consuming screen:** gameplay board cell overlay (planned).
- **Crop:** fills the square tile (a soft-cornered square, so it never reads as a round match piece).
- **Prompt (layer 2, thick):** *[Style block]* A game tile on a transparent background: a thick, fluffy pile of grey dust bunnies and lint in a soft rounded-square shape filling the frame, with a lost biscuit crumb and a tiny feather tucked in. Cute, soft, slightly sparkly, not dirty or gross.
- **Prompt (layer 1, thin):** Same tile, but the dust is a thin, wispy, half-cleared layer that clearly shows it is nearly gone. Keep the same shape, palette, and lighting as layer 2.

### 3. `chapter-02-hallway-cleanup.png`
- **Purpose:** backdrop for the Beat 2 levels.
- **Consuming screen:** gameplay backdrop in both orientations, and the blurred chapter-map background.
- **Crop:** see the background template. The center should be a calm sunlit wooden hallway floor and rug.
- **References:** `chapter-one-garden.png`, `leo-henry-garden-chase.png`, `henry-map-marker.png`.
- **Prompt:** *[Style block]* *[Leo block]* *[Henry block]* Wide 16:9 scene inside a cozy cottage hallway on cleaning day, seen from a small dog's eye level. The center of the image is a calm, softly lit wooden floor with a woven rug and an open back door glowing with garden sunlight at the far end, with nothing busy in the middle. Far left edge: Leo peeks around a doorframe with a stolen biscuit in his mouth, eyes wide. Far right edge: an upright sage-green vacuum stands parked beside a laundry basket, and Henry sits nearby looking back toward Leo, alert and reassuring. Keep the top-right corner soft and low in contrast.

### 4. `chapter-02-scene-01-vacuum-awakens.png`
- **Purpose:** the opening story panel for Beat 2. The vacuum switches on, and Henry steps between it and Leo.
- **Consuming screen:** pre-level story card (planned; not implemented).
- **Crop:** both dogs and the vacuum inside the central square. Keep the bottom 20% as plain floor.
- **References:** all three character references.
- **Prompt:** *[Style block]* *[Leo block]* *[Henry block]* One clear emotional moment. A huge, toy-like sage-green vacuum looms on the right, towering from the dogs' point of view, just switched on, with soft motion puffs and a glowing light. It is comical rather than menacing. Leo crouches on the left with enormous startled eyes and his ears flared, a biscuit dropping from his mouth. Henry stands between Leo and the vacuum, facing it bravely with ears up, his body angled protectively toward Leo. Warm interior light. Plain wooden floor along the bottom of the frame.

### 5. `chapter-03-under-the-bed.png`
- **Purpose:** backdrop for the Beat 3 levels (Milestone 2, "Under-the-bed rescue board").
- **Consuming screen:** gameplay backdrop and chapter map.
- **Crop:** see the background template. Calm bedroom floor in the center.
- **Prompt:** *[Style block]* *[Leo block]* *[Henry block]* Wide 16:9 cozy bedroom at dusk, seen from floor level. The center is a calm, soft rug with warm lamplight and nothing busy. Far left edge: the low, shadowy gap under a quilted bed, where Leo's two big worried eyes and one fluffy paw peek out. Far right edge: Henry lies flat on his belly at the edge of the rug, chin down, looking toward the bed patiently. A dropped plush toy lies between them near the left margin. Soft, safe shadows, never dark or spooky.

### 6. `chapter-03-scene-01-under-the-bed.png`
- **Purpose:** the pre-level story panel. A loud sound has sent Leo under the bed with Henry's toy.
- **Consuming screen:** pre-level story card (planned).
- **Prompt:** *[Style block]* *[Leo block]* *[Henry block]* Low floor-level view under a quilted bed with a dangling bedspread fringe. Leo is squished far under the bed, clutching Henry's red plush ladybug toy (match the attached reference toy), with wide nervous eyes. In the foreground, Henry crawls belly-down into the gap toward him, ears soft and turned forward, gentle and coaxing. A warm sliver of lamplight reaches Leo. Cozy, safe, tender. A plain rug along the bottom of the frame.

### 7. `chapter-03-scene-02-coaxed-out.png`
- **Purpose:** the post-level payoff, showing a small brotherly gesture.
- **Consuming screen:** post-level story card (planned).
- **Prompt:** *[Style block]* *[Leo block]* *[Henry block]* Warm lamplit bedroom. Leo has just crept out from under the quilted bed with a dust bunny on his head, leaning his round body against Henry's side. Henry sits upright beside him, nuzzling the top of Leo's head. The red plush ladybug lies shared between their front paws. Relieved, affectionate, a little funny. A plain rug along the bottom of the frame.

### 8. `leo-map-marker.png`
- **Purpose:** the Art Bible calls for Leo and Henry map markers with recognizable portraits. Only Henry's exists.
- **Consuming screen:** chapter map Leo marker (wiring this in is planned).
- **Crop:** circular crop like `henry-map-marker.png`. Keep the face inside the oval guide.
- **References:** `henry-map-marker.png` (for composition), `leo-expression-sheet.png`.
- **Prompt:** *[Style block]* *[Leo block]* A front-facing head-and-chest portrait of Leo, mischievous and pleased with himself, mouth closed and eyes slightly narrowed, as if he just took something. A saturated warm-orange radial sunburst background in the same style and framing as the attached Henry portrait. Centered, filling the frame.

---

## Wave 2: remaining arc (Beats 4–10)

Use the same structure. Every scene uses the style and identity blocks, and every obstacle uses the obstacle format.

| File | Beat | Prompt core |
|---|---|---|
| `obstacle-storm-cloud.png` | 4 | Chubby grey-violet storm cloud with tiny soft raindrops and a cartoon zigzag of light. Puffy and pouty, not scary. |
| `obstacle-puddle.png` | 4 | Shallow rain puddle tile with ripples and a floating leaf, soft rounded-square shape. |
| `obstacle-comfort-blanket.png` | 4 | Folded cozy knit blanket in warm cream and rust. This is the "spread comfort" tile. |
| `chapter-04-scene-01-thunder.png` | 4 | Window with a stormy sky. Leo is wrapped in a blanket on the cozy spot; Henry presses against him and has dragged over a toy and a slipper as comfort objects. |
| `obstacle-mower-path.png` | 5 | Strip of freshly mowed grass with clippings and a faint tire track. This is the route-hazard tile. |
| `chapter-05-lawnmower-loop.png` | 5 | Backyard background. A toy-like red push mower sits parked in the right margin with Leo hiding behind a flowerpot in the left margin and Henry leading the way. Calm lawn in the center. |
| `obstacle-plastic-bag.png` | 6 | Lightly crumpled translucent plastic shopping bag mid-flutter. Comic and ghostly-soft. |
| `obstacle-can.png` | 6 | Single dented, rattly tin can with a curled paper label (no printed text). |
| `obstacle-mom-slipper.png`, `obstacle-mom-keys.png` | 7 | "Find Mom" clue items: a well-loved pink slipper; a keyring with a paw charm. |
| `chapter-07-scene-01-where-is-mom.png` | 7 | Kitchen doorway. Leo looks lost and small; Henry sniffs Mom's slipper. A warm silhouette of Mom glimpsed through a far window. |
| `chapter-08-poolside.png` | 8 | Sunny poolside background. The pool is only at the far edge of one margin and a clearly dry stone path runs along the center. Henry stands between Leo and the water. |
| `chapter-09-scene-01-special-delivery.png` | 9 | Front door with a soft featureless delivery-person silhouette behind frosted glass and a parcel on the mat. Leo holds the squeaky toy behind a couch cushion; Henry sits beside him at the viewing spot. |
| `obstacle-parcel.png` | 9 | Cardboard parcel tied with twine (no labels or text). This is the drop-item piece. |
| `chapter-10-scene-01-peanut-butter-pad.png` | 10 | Birthday finale. Small party decorations in soft focus. The two dogs lick a round rubber lick pad smeared with peanut butter, shoulder to shoulder, while Mom's hands set it down (no face). |
| `app-icon.png` | — | Leo and Henry heads cheek-to-cheek on a golden garden sunburst. Leo holds the red plush ladybug. Faces fill the center 80%. No text. |

## Handoff record

When an asset is approved, add a row below so the generation prompt, crop, dimensions, and consuming screen stay on record (CLAUDE.md requirement).

| File | Approved | Prompt used | Crop and dimensions | Consuming screen |
|---|---|---|---|---|
| `chapter-02-vacuum-hallway.png` | Yes (2026-10-25) | `ArtworkSource/prompts/backgrounds/` (`_common.txt` + chapter file) | Generated 1536×1024, scaled to 1672 wide, center-cropped to 1672×941 | Chapter 2 gameplay backdrop and map (multi-chapter support not implemented) |
| `chapter-03-under-the-bed.png` | Yes (2026-10-25) | same | same | Chapter 3 backdrop (planned) |
| `chapter-04-thunder-tomatoes.png` | Yes (2026-10-25) | same | same | Chapter 4 gameplay backdrop and map; copied to `SproutAndSmiles/Artwork/` |
| `chapter-05-lawnmower-loop.png` | Yes (2026-10-25) | same | same | Chapter 5 gameplay backdrop and map; copied to `SproutAndSmiles/Artwork/` |
| `chapter-06-bags-and-cans.png` | Yes (2026-10-25) | same | same; bright bag sits behind the pause button, accepted | Chapter 6 gameplay backdrop and map; copied to `SproutAndSmiles/Artwork/` |
| `chapter-07-where-is-mom.png` | Yes (2026-10-25) | same | same | Chapter 7 gameplay backdrop and map; copied to `SproutAndSmiles/Artwork/` |
| `chapter-08-pool-day.png` | Yes (2026-10-25) | same | same | Chapter 8 backdrop (planned) |
| `chapter-09-special-delivery.png` | Yes (2026-10-25) | same | same | Chapter 9 backdrop (planned) |
| `chapter-10-birthday-pad.png` | Yes (2026-10-25) | same | same | Chapter 10 backdrop (planned) |

Chapter backgrounds were generated with the Codex CLI bundled in ChatGPT.app (`codex exec` with image generation), attaching `chapter-one-garden.png`, `henry-map-marker.png`, and `leo-henry-garden-chase.png` as references. Raw outputs were finished with `ArtworkSource/tools/finish_background.py`.
