# Marble Jumble UI visual references

These images/assets are visual direction references for the first major mobile UI screens. They are not pixel-perfect production mocks. Use the visual language, layout hierarchy and motion described here as the implementation target.

## Reference files

- `home.jpg` — Home screen visual reference
- `home-background.svg` — lightweight Canyon background asset for the Home screen
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
- Do not rely on default Godot Button/Label styling for the final presentation. Use custom visual assets/styles where necessary.

## Home

Purpose: make the player's actual marble the hero and establish the world immediately.

### Target composition

- Portrait mobile layout.
- Large Marble Jumble title near the top, using the comic-book logo treatment rather than a plain default Label.
- Use `home-background.svg` as the initial Canyon environment/background asset. It is deliberately lightweight: the background provides atmosphere while the foreground stays simple.
- Foreground is a **real but very simple 3D physical track/plain**, positioned in front of the 2D background so the marble feels grounded in the scene.
- The player's **actual 3D marble scene used by the race** must be reused here. Do not replace it with a 2D sprite or a separate decorative marble.
- The marble should be shown primarily from the side and be large enough to read clearly on a phone.
- The marble rolls continuously on a short track. Prefer a small physical-looking loop / gentle U-shaped turnaround so it can travel left-to-right and right-to-left indefinitely without teleporting or visibly resetting.
- Use actual 3D rotation for the marble as it rolls. Its material/pattern must be the player's current customized marble, exactly as it appears in the game.
- Add a subtle contact shadow under the marble.
- The track should be simple: mostly flat, with a slight incline/curve or tiny bump to make the motion feel physical. Do not build a full course for the Home screen.
- The background does most of the artistic work; do not recreate the Canyon procedurally with large primitive polygons.
- Main navigation remains MARBLE / START / STORE on the home screen.

### Important implementation constraint

Do not try to reproduce the generated poster-style artwork as a fully 3D environment. The intended solution is a hybrid:

**2D illustrated Canyon background + simple 3D physical track + the actual 3D player marble + 2D UI.**

This is intentional and should be treated as the visual architecture for the Home screen.

### Claude Code implementation prompt

> Rework the current Home screen rather than continuing to polish the existing primitive placeholder scene. The current implementation has the correct basic structure but looks like a wireframe because it uses flat gradients, primitive canyon polygons, a tiny generic marble and default-looking controls.
>
> The visual target is the committed `docs/ui-reference/home.jpg`, with `docs/ui-reference/home-background.svg` used as the initial Canyon background asset.
>
> **Do not procedurally recreate the Canyon from primitive Godot polygons.** Use the background asset as a 2D layer.
>
> Build the screen as these layers/components:
>
> 1. `BackgroundArtwork` — portrait 2D Canyon background using `home-background.svg`.
> 2. `LogoArtwork` — bold Marble Jumble comic-book title; avoid plain default Label styling.
> 3. `ForegroundTrack` — a very simple real 3D track/plain in front of the background. It should look physical but contain almost no gameplay complexity.
> 4. `PlayerMarble` — reuse the exact 3D marble scene/material used in the race. It must be the player's current customized marble, not a sprite or separate approximation.
> 5. `MarbleShadow` — subtle contact shadow.
> 6. `HomeNavigation` — custom-styled MARBLE / START / STORE controls.
>
> **Marble idle behaviour:** the marble continuously rolls on the short track. It should move left-to-right and then right-to-left using a small physical-looking turnaround/curve or equivalent smooth loop. Do not teleport it back to the start. The marble must visibly rotate as it travels. The animation should be slow and relaxing, not a race.
>
> The foreground should remain deliberately simple. The visual richness comes from the illustrated background, the polished marble, lighting/shadow and strong UI composition.
>
> The result should read as a polished mobile game home screen, not a Godot debug screen. Do not add arbitrary decorative UI, extra HUD elements, or a full 3D Canyon environment.

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

Use these references as visual direction, not as a reason to construct every element as a complex 3D object. The Godot implementation should favour simple reusable UI primitives, 2D artwork where appropriate, and the existing 3D marble/physics systems where physical motion matters.

The priority is consistent composition, hierarchy, colour, typography, material quality, lighting and interaction language rather than reproducing every decorative detail from the generated references.
