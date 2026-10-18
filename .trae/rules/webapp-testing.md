---
description: "Use when verifying a web application in a real browser, debugging a UI issue, or writing end-to-end tests against a running app."
---


# Web app testing

## Drive a real browser, and start it explicitly

```ts
import { test, expect } from '@playwright/test'

test('adds a todo', async ({ page }) => {
  await page.goto('http://localhost:3000')
  await page.getByRole('textbox', { name: 'What needs doing' }).fill('write tests')
  await page.getByRole('button', { name: 'Add' }).click()
  await expect(page.getByText('write tests')).toBeVisible()
})
```

Playwright starts the dev server from `webServer` in the config, so do not also
start one by hand and assume the test picked it up. A test against a stale
server is the most common cause of a fix that appears not to work.

## Wait for conditions, never for time

```ts
// Fragile: slow on a cold cache, still racy on a loaded machine
await page.waitForTimeout(500)

// Correct: waits for the state you actually need
await expect(page.getByRole('status')).toHaveText('3 items')

// Correct: waits for the network request that fetches the data
await page.waitForLoadState('networkidle')

// Correct: auto-waiting, when the assertion is on the element itself
await expect(page.getByText('Saved')).toBeVisible()
```

A sleep passes when the machine is idle and fails under load, which means it
reports the load rather than the bug. Every Playwright assertion auto-waits, so
most explicit waits are unnecessary.

## Locate elements by role and accessible name

```ts
page.getByRole('button', { name: 'Delete', exact: true })   // good
page.locator('.btn-danger > span:nth-child(2)')           // brittle
page.locator('[data-testid="delete-42"]')                  // works, says nothing
```

The accessible name is also what a screen reader announces, so preferring role
and name tests accessibility as a side effect. When no accessible name exists,
adding one is usually the correct fix rather than reaching for a test id.

Scope by accessible container, not by DOM position, and prefer
`getByRole('row', { name: /invoice-42/ })` to a chain of `nth-child` selectors.

## Treat console errors and failed requests as first class signal

An end-to-end test that passes while the page logs `TypeError` and 404s on an
asset is not a passing test. Fail on both:

```ts
test.beforeEach(async ({ page }) => {
  const errors: string[] = []
  page.on('console', m => m.type() === 'error' && errors.push(m.text()))
  page.on('pageerror', e => errors.push(e.message))
  page.on('response', r => {
    if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`)
  })
  ;(page as any).__errors = errors
})

test.afterEach(async ({ page }) => {
  expect((page as any).__errors).toEqual([])
})
```

## Keep end-to-end tests few and shallow

End-to-end tests are slow, and their value falls off sharply with depth. Use
them for the journeys where a unit test cannot prove the wiring:

- One user-visible flow per test.
- Setup through the API or a fixture, not by clicking through the app to reach
  the state under test.
- No branching inside a test. Two paths are two tests.
- No assertions on internal state. Assert what the user sees.

Cover validation rules and formatting at the unit level; cover the wiring here.

## When a UI bug will not reproduce

Look for it in this order, and it will usually be one of the first three:

1. **Race** — the assertion ran before the update landed. Wait for the state.
2. **Hydration** — server and client markup differ, so the element is replaced
   after paint. This produces "works in production, fails in test" because
   timing differs.
3. **Viewport** — the element is off-screen or clipped rather than absent.
   `toBeVisible()` is false for both.
4. **Event delegation** — the handler is on an ancestor that the test replaced.

Take a trace when a test fails intermittently:

```sh
npx playwright test --trace on
npx playwright show-trace trace.zip
```

The trace shows every action, screenshot and network request in order, which
turns "flaky" into a specific interleaving.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The unit tests cover it." | Unit tests cannot prove the components are wired together correctly. |
| "I will add a sleep to stabilise it." | You have added a race that happens to pass on your machine. |
| "This selector is fine." | It breaks on the first markup change, and it tests the CSS rather than the behaviour. |
| "One long test for the whole flow is simpler." | It stops at the first failure, so you learn one fact per run instead of ten. |
| "The screenshot matches, so it works." | A screenshot can match while the console is full of errors. |
