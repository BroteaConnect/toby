# Toby documentation

Toby is a static [Astro](https://astro.build) site (landing page with a
requirements form) plus a small in-browser game. This folder documents the
site's user-visible features.

## Pages / routes
- `/` — landing page with the requirements form (see the root `README.md`).
  The hero now links to the game via a "Play the game 🚽" call to action.
- `/game` — [Flappy Toilet](./game.md), a client-side canvas game.

## Tech notes
- Astro 5, `output: 'static'` — every `.astro` page under `src/pages/` is
  prerendered to `dist/<route>/index.html` and served by nginx.
- No backend and no database are used by the site itself. The only persisted
  state is the game's high score, kept in the browser's `localStorage`.
