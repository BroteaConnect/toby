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

The target URL comes from the `PUBLIC_REQUIREMENTS_ENDPOINT` env var,
read at build time and rendered onto the form's `data-endpoint`
attribute. On submit the handler sends:

```json
{
  "project": "toby",
  "source": "landing_form",
  "submitted_by": "<name> <<email>>",
  "content": "<content>"
}
```

```
POST <PUBLIC_REQUIREMENTS_ENDPOINT>
Content-Type: application/json
```

## Submit states

The submit handler (`e.preventDefault()`, no full-page reload) drives the
`#form-status` message and the "Send" button through these states:

1. **Submissions not enabled** — if `PUBLIC_REQUIREMENTS_ENDPOINT` was
   unset at build time (empty `data-endpoint`), the handler short-circuits
   before any request: status shows `Submissions are not enabled yet.`
   and the button stays usable.
2. **Sending** — status shows `Sending...` and the "Send" button is
   **disabled** while the POST is in flight.
3. **Success** — on a `res.ok` response the form is reset and status shows
   `Thank you! We received your input.`
4. **Failure** — on a non-OK response or a network error, status shows
   `Something went wrong — please try again later.` (the entered values
   are kept).
5. In both the success and failure paths the button is **re-enabled**
   afterwards via a `finally` block, returning the form to idle.

## Double-submit guard

Disabling the button on send and re-enabling it in a `finally` block means
every exit path (success, HTTP error, thrown network error) restores the
button exactly once. While a request is in flight the button is disabled,
so rapid double-clicks cannot fire multiple overlapping POSTs.

The DOM lookups are null-safe (`form?.querySelector`,
`form?.addEventListener`, guarded `button` writes), so the script does not
throw if the expected markup is absent.
