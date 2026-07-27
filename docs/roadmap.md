# Public roadmap (`/roadmap`)

`src/pages/roadmap.astro` (route `/roadmap`) is a self-contained public
roadmap page: no Layout, no React island, no env vars. Everything —
markup, fetch logic, styles — lives in that one file. The hero on `/`
links to it ("Roadmap" link under the CTA), and the page links back to
`/` ("Back to home").

## Data source

The project identity is hardcoded at build time in the frontmatter:

```astro
const PROJECT_NAME = 'Toby';
const PROJECT_SLUG = 'toby';
const ENDPOINT = `https://api.brotea.dev/roadmap?project=${PROJECT_SLUG}`;
```

The endpoint is rendered onto `#roadmap`'s `data-endpoint` attribute and
fetched **client-side** on page load with an 8-second deadline
(`AbortSignal.timeout(8000)`):

```
GET https://api.brotea.dev/roadmap?project=toby
```

Expected JSON shape:

```json
{
  "items": [
    { "title": "Dark mode", "description": "Optional.", "status": "shipped" }
  ]
}
```

- `title` — required, rendered bold.
- `description` — optional, rendered as a smaller paragraph under the title.
- `status` — one of `planned`, `in_progress`, `shipped`. Items with any
  other status are **skipped** silently (no column matches, no error).
- A missing `items` key is treated as an empty list (`data.items ?? []`).

## Columns & states

Items are distributed into three columns keyed by `data-status`:
**Planned**, **In progress**, **Shipped**.

1. **Loading** — `#roadmap-status` shows `Loading roadmap…` and the
   columns are `hidden`.
2. **Success** — the status line is hidden and the columns are shown.
   Any column that ends up with no items gets a dashed placeholder entry:
   `Nothing here yet.`
3. **Failure** — on a non-OK response, a network error, or the 8s
   timeout, the columns stay hidden and the status line shows:
   `The roadmap is not available right now — please check back later.`

## Implementation notes

Two rules in the page's `<style>` block look redundant but are not:

- **Global styles for client-created nodes.** The `<li>` items are built
  with `document.createElement`, so they never receive Astro's scope
  attribute — scoped selectors would not match them. The item rules use
  `:global()`:

  ```css
  .column :global(li) { border: 1px solid #eee; ... }
  ```

- **Explicit `.columns[hidden]` rule.** `.columns` has
  `display: grid`, and any author `display` rule beats the UA's
  `[hidden] { display: none }`. Without the explicit override the
  columns would be visible while "hidden":

  ```css
  .columns { display: grid; ... }
  .columns[hidden] { display: none; }
  ```
