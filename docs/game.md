# Flappy Toilet 🚽

An interactive Flappy Bird clone where the player is a toilet emoji instead of
a bird. It is a self-contained, client-side canvas game.

## Where to find it
- Route: **`/game`** (served as `dist/game/index.html`).
- Entry point: the landing page (`/`) hero has a **"Play the game 🚽"** link.
- From the game, the **"← Back"** link returns to `/`.

## How to play
The goal is to keep the toilet flying through the gaps between pipes for as
long as possible. Each frame gravity pulls the toilet down; every input gives
it an upward impulse ("flap").

| Action | Controls |
| ------ | -------- |
| Start / flap | Click, tap, `Space`, or `ArrowUp` |
| Restart (after game over) | Click, tap, `Space`, `ArrowUp`, or `R` |

The canvas is focusable (`tabindex="0"`) and is focused automatically on load
and on the first flap, so keyboard controls work immediately.

## Game flow
1. **Ready** — start screen showing "Flappy Toilet 🚽", a prompt, and the
   current best score. Any flap input starts the game.
2. **Playing** — the toilet falls under gravity, pipes scroll in from the
   right, and the live score is drawn at the top center.
3. **Game over** — reached on any collision; shows the final score, the best
   score, and a retry prompt.

## Mechanics
- **Gravity & flap:** gravity `1400 px/s²` accelerates the toilet downward; a
  flap sets its velocity to `-420 px/s` (upward impulse).
- **Pipes / obstacles:** green pipe pairs with a `150 px` vertical gap, `60 px`
  wide, spawned every `220 px` of horizontal travel and scrolling left at
  `150 px/s`. Off-screen pipes are recycled. The gap position is randomized
  each spawn.
- **Scoring:** +1 each time a pipe scrolls past the toilet's x position.
- **Collision / game over:** an axis-aligned box around the toilet
  (`playerX = 90`, half-size `16 px`) versus each pipe rectangle, plus the
  floor and ceiling. Any hit ends the run.
- **High score:** persisted in `localStorage` under the key
  `toby.flappy.highscore`. Reads/writes are wrapped in `try/catch` so
  private-browsing mode does not break the game. It is browser-local only —
  never sent to any server.

## Tech
- A single Astro page, `src/pages/game.astro`, with an inline browser
  `<script>` and scoped `<style>` — no imports, no dependencies, no assets.
- Vanilla JavaScript on an HTML5 `<canvas>` 2D context, driven by a
  `requestAnimationFrame` loop with delta-time (clamped to `0.05 s` after tab
  switches). State machine: `ready` → `playing` → `over`.
- Fixed logical resolution of `360 × 540`; the backing store is scaled by
  `devicePixelRatio` for crisp HiDPI rendering while physics stay in logical
  units. The element is scaled responsively via CSS (`aspect-ratio: 360 / 540`,
  max width `420 px`).
- The toilet is the 🚽 emoji drawn with `ctx.fillText` (an emoji-capable font
  stack), with a blue-square fallback if the glyph reports zero width.
