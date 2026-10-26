# Art Bible

## Visual goal

The game should feel like a premium illustrated storybook brought to life: warm, lush, readable, affectionate, and slightly exaggerated. It may share the broad coziness of popular match-three garden games, but it must use original characters, environments, UI, and artwork.

The current Chapter One art establishes the target rendering style: storybook-realistic 3D painting, soft fur detail, golden-hour lighting, saturated garden colors, and expressive but recognizable versions of the real dogs.

## Character identity

### Leo

- Golden-brown coat; cream muzzle and chest.
- Very round body and full cheek fur.
- Floppy feathered ears.
- Dark round eyes and a small brownish nose.
- His silhouette must remain wider and rounder than Henry's.
- Expressions may be exaggerated, but his coat pattern and proportions should remain consistent.

### Henry

- Long, predominantly dark chocolate-brown coat (not black) with a white-and-cream muzzle, chest ruff, and paws.
- Tan eyebrow spots and cheek markings.
- `henry-map-marker.png` is the reference for his exact coat color.
- Tall, pointed ears are essential to his silhouette.
- Large brown eyes and a small brownish nose.
- Slightly more alert, upright, and angular than Leo.

## Match-piece rules

- Every ordinary match piece is a circle.
- A normal piece must never use a unique outline that makes it resemble a power-up.
- The six Leo expressions need substantially different eyes, mouths, head angles, and silhouettes—not just different background colors.
- Backgrounds are highly saturated radial bursts: red, orange, yellow, magenta, violet, and green.
- Leo's face should occupy most of the 512 × 512 source image and remain readable around 42–50 points on an iPhone.
- Power-ups are communicated with separate badges and effects layered by the app.

Current piece files live in `SproutAndSmiles/Artwork/LeoPieces/`.

## Chapter background rules

Gameplay in landscape uses a chapter-specific illustrated backdrop behind the centered square board.

- Preferred source aspect ratio: 16:9 or similarly wide.
- Current reference size: 1672 × 941 pixels.
- Keep the central 55% calm and free of characters because the board covers it.
- Put character moments and richer detail in the outer side margins.
- Keep contrast behind the pause button under control.
- The same location and palette should continue across every level in a chapter.
- Variations may change time of day, weather, or small story props without making levels feel unrelated.

Chapter One currently uses `SproutAndSmiles/Artwork/chapter-one-garden.png`.

## Map artwork rules

- Maps should resemble illustrated places, not plain menus.
- The route must remain legible above the background.
- Level nodes need clear locked, unlocked, current, and completed states.
- Henry and Leo markers should use recognizable portraits.
- Captions must remain readable in portrait and landscape.
- Environmental props can foreshadow upcoming events: a vacuum cord, storm cloud, lawnmower trail, fluttering bag, pool float, delivery parcel, or peanut-butter pad.
- Avoid putting important painted details directly beneath text or nodes.

## Story-panel composition

- Use one clear emotional beat per panel.
- Favor readable poses and faces over crowded action.
- Henry should visually orient toward Leo when helping him.
- Scary objects should be large from Leo's perspective but still playful and harmless.
- Leave safe space for optional app-rendered captions; do not bake words into images.

## File conventions

- Lowercase kebab-case filenames.
- Character portrait: `character-purpose-expression.png`.
- Chapter background: `chapter-##-short-name.png`.
- Story panel: `chapter-##-scene-##-short-name.png`.
- Obstacle: `obstacle-short-name.png`.
- Export final raster assets as PNG in sRGB.
- Keep working files outside the app bundle or in a clearly named `ArtworkSource/` folder.
- Do not overwrite approved assets without preserving a reviewable version or commit.

## Priority artwork queue

1. Vacuum obstacle and frightened-Leo/helpful-Henry story panel.
2. Under-the-bed environment and story panel.
3. Thundercloud, rain, and comfort-object overlays.
4. Lawnmower path obstacle.
5. Plastic bag and rattling-can blockers.
6. “Find Mom” clue objects.
7. Poolside chapter variation with a clearly dry safe route.
8. Delivery-person silhouette and parcel props.
9. Birthday peanut-butter pad finale.
10. App icon and launch artwork built from approved character art.

## Artwork review checklist

- Does each dog still look like the correct real dog?
- Is Leo round, golden-brown, and floppy-eared?
- Is Henry dark chocolate brown (not black) with white-and-cream chest, tan eyebrows, and pointed ears?
- Is the emotion immediately readable on a phone?
- Does Henry's pose support or protect Leo when the scene calls for it?
- Is the center clear where gameplay requires it?
- Is there any accidental text, watermark, extra limb, duplicate animal, or inconsistent marking?
- Does the asset remain legible after cropping in both iPhone orientations?
