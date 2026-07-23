# Requirements form (`/`)

The landing page (`src/pages/index.astro`, route `/`) hosts the "Tell us
what you need" form. It collects three required fields and POSTs them as
JSON to an external endpoint.

## Fields

| Field     | Input      | Required | Max length |
|-----------|------------|----------|------------|
| `name`    | text       | yes      | 120        |
| `email`   | email      | yes      | 200        |
| `content` | textarea   | yes      | 4000       |

## Endpoint & configuration

The target URL is resolved at **build** time in `src/pages/index.astro`:

```astro
const DEFAULT_ENDPOINT = 'https://api.brotea.dev/requirements';
const ENDPOINT = import.meta.env.PUBLIC_REQUIREMENTS_ENDPOINT?.trim() || DEFAULT_ENDPOINT;
```

The default is compiled into the bundle, so the form works out of the box
with no configuration. `PUBLIC_REQUIREMENTS_ENDPOINT` is an *optional*
override and is used verbatim as the POST target (surrounding whitespace is
trimmed). The `||` is deliberate — the Docker ARG defaults to an empty
string, which is not nullish, so an empty or whitespace-only value falls
back to the default instead of shipping a dead endpoint.

The resolved URL is rendered onto the form's `data-endpoint` attribute. On
submit the handler sends:

```json
{
  "project": "toby",
  "source": "landing_form",
  "submitted_by": "<name> <<email>>",
  "content": "<content>"
}
```

```
POST https://api.brotea.dev/requirements
Content-Type: application/json
```

The request carries a 15-second deadline (`AbortSignal.timeout`), so an
unreachable API surfaces an error instead of leaving the form stuck.

## Build time vs runtime (deploy note)

Astro inlines `PUBLIC_*` variables when `astro build` runs, so the endpoint
is frozen into `dist/index.html`. Setting the variable on the running
container has **no effect** — that stage only serves static files through
nginx.

The `build` stage of the `Dockerfile` therefore declares it explicitly
(ARGs are not inherited across `FROM`, and Docker silently discards a
`--build-arg` whose ARG is not declared in the stage that uses it):

```dockerfile
ARG PUBLIC_REQUIREMENTS_ENDPOINT=""
ENV PUBLIC_REQUIREMENTS_ENDPOINT=$PUBLIC_REQUIREMENTS_ENDPOINT
RUN npm run build
```

```bash
docker build --build-arg PUBLIC_REQUIREMENTS_ENDPOINT=https://example.com/requirements .
```

In Coolify the override must be flagged as a **build** variable so it is
passed as `--build-arg`; a plain runtime variable never reaches the build.

A redeploy must also not reuse a cached `RUN npm run build` layer, or the
previous bundle ships again and the change appears to have no effect. The
`ENV` line sits above `RUN npm run build`, so changing the value changes
that layer and invalidates the cached build.

## Verifying the endpoint is baked in

`npm test` runs `astro build`. There is no test runner in this repo, so a
green build only proves the site compiles — never that the form can
submit. The bundle is what has to be checked:

```bash
npm ci && npm run build
grep -o 'data-endpoint="[^"]*"' dist/index.html
# data-endpoint="https://api.brotea.dev/requirements"
```

CI runs exactly that assertion after the build
(`.github/workflows/ci.yml`):

```yaml
- run: npm run build
- name: Assert the requirements endpoint is baked into the bundle
  run: grep -q 'data-endpoint="https://[^"]\+"' dist/index.html
```

The step fails the pipeline if `data-endpoint` is missing, empty, or not an
`https://` URL — the exact regression that once shipped a form which could
never submit.

## Submit states

The submit handler (`e.preventDefault()`, no full-page reload) drives the
`#form-status` message and the "Send" button through these states:

1. **Submissions not enabled** — defensive only. If `data-endpoint` is
   empty the handler short-circuits before any request: status shows
   `Submissions are not enabled yet.` and the button stays usable. No
   build configuration can reach this state any more, because an empty
   `PUBLIC_REQUIREMENTS_ENDPOINT` falls back to the compiled-in default;
   only editing the markup could.
2. **Sending** — status shows `Sending...` and the "Send" button is
   **disabled** while the POST is in flight.
3. **Success** — on a `res.ok` response the form is reset and status shows
   `Thank you! We received your input.`
4. **Failure** — the entered values are kept and the real error is logged
   to the console. The message distinguishes the cause:
   - timeout: `That took too long - please try again in a moment.`
   - rate limited: `Too many submissions - please wait a minute and try again.`
   - anything else: `Something went wrong (HTTP 404) - please try again later.`,
     with the status code or the browser's network error in parentheses.
5. In both the success and failure paths the button is **re-enabled**
   afterwards via a `finally` block, returning the form to idle.

## Double-submit guard

Disabling the button on send and re-enabling it in a `finally` block means
every exit path (success, HTTP error, thrown network error) restores the
button exactly once. While a request is in flight the button is disabled,
so rapid double-clicks cannot fire multiple overlapping POSTs.

The DOM lookups are null-safe (`form?.querySelector`,
`form?.addEventListener`, guarded `button` writes, and an early return
when `#form-status` is missing), so the script does not throw if the
expected markup is absent.
