# Leo & Henry's Yard

The home-decorating screen between levels, opened from the house button on the chapter map or the "Our Yard" card on the pause screen. It replaces the earlier emoji "Our Cozy Corner" sheet.

## Economy

- Every level won for the first time earns one treat (100 levels, 100 treats). Replays and DEBUG previews earn nothing.
- Treats are never stored on their own: `treats = wins - cost of built projects`. This keeps old saves working (players with existing wins arrive with treats to spend) and avoids double-spending.
- Treats cannot be bought. There are no ads, timers, or energy.
- Built projects are saved on-device in `UserDefaults` key `yard.choices` (`[spotID: styleIndex]`). The DEBUG reset clears it with the rest of progress.

## Projects

| Spot | Cost | Styles |
|---|---|---|
| Flower Bed | 1 | Tulips, Sunflowers, Lavender |
| Doghouse | 3 | Red Barn, Blue Cottage, Pink Castle |
| Splash Spot | 5 | Paddling Pool, Duck Pool, Stone Fountain |
| Nap Spot | 8 | Striped Bed, Knit Basket, Canopy Bed |
| Toy Box | 11 | Wicker Basket, Wooden Chest, Garden Bucket |
| Mom's Bench | 14 | Wicker Loveseat, Garden Bench, Porch Swing |
| Shade Tree | 17 | Apple Tree, Cherry Blossom, Lemon Tree |
| Garden Arch | 20 | Rose Arch, Lantern Arch, Party Arch |

79 treats finish the yard, so it completes around the start of Chapter Eight with treats to spare. Any affordable spot can be built in any order; switching styles on a built spot is free.

## Art

- `SproutAndSmiles/Artwork/Yard/yard-background.png`: 1672x941 painted, empty backyard stage (finished with `finish_background.py`).
- `yard-<spot>-<1|2|3>.png` and `yard-dog-leo.png` / `yard-dog-henry.png`: transparent sprites trimmed to visible pixels with `ArtworkSource/tools/finish_sprite.py` (max side 600 px). The bottom edge is the ground contact point; `YardView.swift` positions each sprite by bottom-center.
- Prompts are in `ArtworkSource/prompts/yard/` (`bg-*`, `sprite-common.txt` + `<spot>-<n>.txt`, `dog-*`). They were generated with the Codex CLI image tool, using `chapter-one-garden.png` and the red barn doghouse as style references and `leo-henry-garden-chase.png` / `henry-map-marker.png` for the dogs.
