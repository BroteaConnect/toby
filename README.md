# Toby

Landing page with a requirements form, generated from Brotea's
`landing-astro` template.

## Template placeholders (replaced by the new-project skill)
- `__PROJECT_NAME__` — human-readable project name
- `__PROJECT_SLUG__` — kebab-case slug (also the repo name)
- `__PROJECT_DESCRIPTION__` — one-sentence idea/description
- `project-slug-placeholder` — same slug, used in machine-validated name
  fields (package.json) where leading underscores are illegal

## Configuration
- `PUBLIC_REQUIREMENTS_ENDPOINT` — *optional* override for the URL that
  receives the form's JSON POST (`{project, source, submitted_by, content}`
  → requirements table). The default, `https://api.brotea.dev/requirements`,
  is compiled into the bundle, so the form works out of the box.
  Because Astro inlines `PUBLIC_*` vars at **build** time, this is a Docker
  **build ARG**, not a runtime env var — pass it with
  `docker build --build-arg PUBLIC_REQUIREMENTS_ENDPOINT=https://example.com/requirements .`
  In Coolify it must be flagged as a **build** variable so it becomes a
  `--build-arg`. Setting it on the running container has no effect.
  The override must be an absolute URL with no trailing slash.

## Commands
- `npm install` · `npm run dev` · `npm run build` (output in `dist/`)

## Documentation
- [Requirements form (`/`)](docs/form.md) — fields, endpoint payload, and
  submit states (idle → Sending... → Thank you!/error), including the
  double-submit guard.
