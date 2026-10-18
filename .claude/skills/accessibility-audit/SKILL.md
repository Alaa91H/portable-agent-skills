---
name: accessibility-audit
description: Use when auditing a page or component for WCAG conformance, screen-reader support, or keyboard operability, or when accessibility is named as a requirement.
---

# Accessibility audit

## Audit in this order

Later passes depend on earlier ones. A contrast audit of a control that cannot
be reached by keyboard is wasted effort.

1. **Keyboard** — can it be operated at all?
2. **Semantics** — is the right element used?
3. **Names and roles** — does assistive tech know what it is and what to call it?
4. **Contrast and visibility** — can it be perceived?
5. **Dynamic behaviour** — are changes announced?
6. **Motion and timing** — can everyone tolerate it?

## 1. Keyboard

Tab through the entire flow without touching the mouse. Record every element
that cannot be reached, and every element that is reached in an order that does
not match the visual order.

```js
// Elements that should be interactive but are not reachable
document.querySelectorAll('[onclick]:not(button):not(a[href])')
document.querySelectorAll('[tabindex]:not([tabindex="-1"]):not([tabindex="0"])')
```

Positive `tabindex` is almost always a bug: it overrides DOM order for the whole
page. Use `0` to make something focusable, `-1` to make it programmatically
focusable only.

For each dialog: focus must move into it on open, be trapped while open, and
return to the trigger on close.

## 2. Semantics

The cheapest accessibility work is deleting the wrong element.

```html
<!-- Wrong: not focusable, no role, no key handling, invisible to AT -->
<div class="btn" onclick="submit()">Save</div>

<!-- Right: all of it for free -->
<button type="button" class="btn">Save</button>
```

Replace with native elements first: `button` for actions, `a` with `href` for
navigation, `label` with `for` for form controls, `ul`/`li` for lists,
`table` for tabular data with `th` and a `scope`. Add ARIA only for what HTML
cannot express, and the first rule of ARIA is not to use it.

Every image needs `alt`. Decorative images take `alt=""`, which is different from
omitting it. Missing alt is worse than wrong alt, because screen readers announce
the filename.

## 3. Names and roles

Every interactive element needs an accessible name. In order of preference:

1. Visible text content.
2. An associated `<label for="id">`.
3. `aria-labelledby` pointing at visible text.
4. `aria-label` as a last resort, since it is invisible and untranslatable.

Icon-only buttons are the usual failure:

```html
<button aria-label="Close dialog"><TrashIcon /></button>   <!-- aria-label must match the icon's action -->
```

Check the role is not being overridden wrongly. A `<nav>` with
`role="presentation"` is worse than a plain `<div>`.

Landmarks: one `main`, a `header`, a `nav`, and a `footer`. A screen-reader user
navigates by landmark, so missing ones make a long page unnavigable.

## 4. Contrast and visibility

- Body text 4.5:1, large text and UI boundaries 3:1.
- Check the states that are styled differently: hover, focus, disabled, visited.
- Check focus visibility explicitly, since focus rings are often removed.
- Check zoom at 200% and a 320px viewport for clipping and horizontal scroll.

## 5. Dynamic content

A screen reader does not notice content that was not there when the page loaded.
Announce it:

```html
<div role="status" aria-live="polite">3 results found</div>
```

`polite` waits for a pause and is right for most updates. `assertive`
interrupts and is reserved for errors the user must know about immediately.

For errors on submission, move focus to an element containing the message rather
than relying on a live region alone; some combinations announce inconsistently.

A validation message tied to an input needs `aria-describedby` pointing at the
message element's id, or the error is never read.

## 6. Motion and timing

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Also check: no auto-playing motion over 5 seconds without a pause control, and
no time limit without a way to extend it.

## Automated tooling is a floor, not the audit

```sh
npx axe-core http://localhost:3000 --chromedriver-path=$(which chromedriver)
npx pa11y http://localhost:3000 --standard WCAG2AA
```

Run it, fix what it finds, then assume the remaining third is what matters:
keyboard operability, focus order, names, and live-region behaviour are largely
invisible to static analysis. Treat a clean automated report as permission to
start the manual pass, never as evidence of conformance.

## Report honestly

Separate the three categories, because they imply different work:

| Category | Meaning | Action |
| --- | --- | --- |
| **Blocker** | A user cannot complete the task at all | Fix before release |
| **Barrier** | The task is possible but unreasonably hard | Fix, or record with a plan |
| **Annoyance** | Works, with effort | Fix opportunistically |

State the WCAG success criterion by number and level for each finding, since
that is what makes the report actionable by someone who did not do the audit.
Claiming conformance you have not verified is worse than reporting a gap, because
it transfers the false confidence to someone else.