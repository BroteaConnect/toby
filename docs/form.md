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

The target URL defaults to `https://api.brotea.dev/requirements`, compiled
into the bundle, so the form works out of the box.
`PUBLIC_REQUIREMENTS_ENDPOINT` is an *optional* override; because Astro
inlines `PUBLIC_*` vars at **build** time it must be passed as a Docker
build ARG (see the README), never as a runtime env var. Either way the
resolved URL is rendered onto the form's `data-endpoint` attribute. On
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

## Submit states

The submit handler (`e.preventDefault()`, no full-page reload) drives the
`#form-status` message and the "Send" button through these states:

1. **Submissions not enabled** — defensive only. Since the endpoint has a
   compiled-in default this is unreachable unless someone deliberately
   builds with an empty `PUBLIC_REQUIREMENTS_ENDPOINT`. If `data-endpoint`
   is empty the handler short-circuits before any request: status shows
   `Submissions are not enabled yet.` and the button stays usable.
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
