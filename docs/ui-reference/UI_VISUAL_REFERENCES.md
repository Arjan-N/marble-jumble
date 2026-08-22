# Marble Jumble UI visual references

These three images are visual direction references for the first major mobile UI screens. They are not pixel-perfect production mocks. Use the visual language and layout hierarchy as the implementation target.

## Reference files

- `home.jpg` — Home screen
- `round-start.jpg` — Tournament round/course setup
- `shop.jpg` — Shop

All reference images in this folder are portrait mobile references normalized to approximately 9:16. The game itself should use responsive portrait layouts rather than hard-coded dimensions.

## Shared visual language

- Portrait mobile-first UI.
- Comic-book-inspired presentation with thick dark outlines, halftone texture, strong silhouettes and bold display typography.
- Warm canyon/orange is the main Marble Jumble visual identity, while individual course themes can change the environment palette.
- UI should feel tactile and physical rather than futuristic, glossy or generic-mobile.
- Use restrained panels and strong hierarchy. The marble/course content is the visual focus.
- Avoid excessive gradients, bloom, glassmorphism, tiny text and dense HUDs.

## Home

Purpose: make the player's marble the hero and establish the world immediately.

- Portrait layout.
- Large Marble Jumble title near the top.
- Static illustrated/stylised Canyon environment can provide most of the visual richness.
- Foreground should be simple: a short, mostly flat physical track/plain.
- The player's current marble is shown in a side view and rolls slowly across the foreground continuously.
- The marble should visibly rotate so its customization is immediately apparent.
- Keep the environment lighter and simpler than the illustrated reference; the marble and primary action should remain dominant.
- Main navigation can be MARBLE / START / STORE on the home screen.

## Round start / tournament setup

Purpose: the tournament has already been started; the player is preparing to release the field.

- Portrait layout.
- Course selection is the main selectable element.
- Use an automatically cycling/rotating course carousel. The currently selected course is centered and clearly highlighted; adjacent courses remain partially visible.
- Show several other courses in the carousel to make the roulette/carousel feel active.
- The current course should communicate its name and visual identity.
- Below the course carousel, show the 12 marbles in a **4 x 3 grid**.
- The player does **not** choose a marble. The player is one of the 12 participants and the other 11 are opponents.
- Label the section **MARBLES**, not Opponents.
- The player's marble is always part of the 12 and is clearly highlighted using the normal persistent subtle highlight plus a stronger selection treatment for this setup screen.
- The other 11 marbles are cosmetic variants only; do not present them as selectable characters or give them personality/character portraits.
- Do not show the normal home bottom navigation once a tournament/round setup has started.
- The setup screen leads into the physical starting sequence and barrier release interaction.

## Shop

Purpose: sell/unlock cosmetic marble items and courses without turning the UI into an inventory/RPG interface.

- Portrait layout.
- Large SHOP header with the same comic-book language as the rest of the game.
- Persistent currency display.
- Featured item area at the top with a large marble preview and purchase information.
- Tabs/categories should be simple and physical-looking.
- Show a grid/list of marble cosmetics with price, owned/locked state and rarity only where useful.
- Include a **Courses** category/section in the shop. Courses are purchasable/unlockable content alongside marble cosmetics.
- Course cards should show a strong illustration, course name, rarity/difficulty or short descriptor, and unlock price.
- The player is never buying a gameplay advantage; progression is cosmetic and content-unlock focused.
- Keep the shop visually consistent with the Canyon/comic visual language.

## Implementation guidance

Use these images as visual references, not as a reason to construct every element as a complex 3D object. The Godot implementation should favour simple reusable UI primitives, 2D artwork where appropriate, and the existing 3D marble/physics systems where physical motion matters.

The priority is consistent composition, hierarchy, colour, typography and interaction language rather than reproducing every decorative detail from the generated references.
