# Card artwork

Each file under `animals/` is the artwork for one card, referenced by its
`artwork` path in
[`lib/data/card_catalog.dart`](../../lib/data/card_catalog.dart)
(e.g. `assets/cards/animals/lion.png` for the Lion card). The card system
never hardcodes a path in the UI — it only ever reads `card.artwork`, so
swapping a file here (or changing the path in the catalog) is the only
step needed to update a card's art. No UI or model code changes.

## Current state

Every image right now is a generated placeholder (a plain gold paw
print on a sage background) so the app has something real to render.
They all share the same template so the card grid looks consistent.
Replace them with real artwork whenever it's ready.

## Image spec for replacements

- **Format:** PNG
- **Size:** square, at least 480x480 px. `TradingCardView` always
  crops/scales artwork with `BoxFit.cover` to fill its box, and that
  box's shape differs slightly between the collection grid, deck
  builder, and hand/field on the game board — a square source crops
  evenly from the center in all of them. Keep the subject centered and
  leave some margin, since the edges may get cropped.
- **Naming:** lowercase animal name matching the `id` used in
  `card_catalog.dart`, e.g. `tiger.png`
- Art doesn't need to match the UI's rounded corners or borders
  itself — the card frame around it handles that.

If a card's artwork path is empty or the file fails to load, the UI
automatically falls back to a generic placeholder icon instead of
crashing, so it's safe to add a new card before its art exists.
