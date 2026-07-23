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
  `--build-arg`. Setting it on the running container has no effect, and a
  redeploy must not reuse the cached `RUN npm run build` layer.
  The override is used verbatim as the POST target, so give the full
  absolute URL including its path; an empty value falls back to the default.
  See [docs/form.md](docs/form.md#build-time-vs-runtime-deploy-note).

## Commands
- `npm install` · `npm run dev` · `npm run build` (output in `dist/`)
- `npm test` — runs `astro build`. There is no test runner in this repo, so
  a green build is not evidence that the form works.
- CI (`.github/workflows/ci.yml`) builds and then greps `dist/index.html`
  for `data-endpoint="https://..."`, failing if the requirements endpoint
  was not baked into the bundle:
  ```bash
  grep -o 'data-endpoint="[^"]*"' dist/index.html
  ```

## Documentation
- [Requirements form (`/`)](docs/form.md) — fields, endpoint payload, and
  submit states (idle → Sending... → Thank you!/error), including the
  double-submit guard, the build-time vs runtime endpoint rules, and how to
  verify the endpoint is baked into the bundle.
