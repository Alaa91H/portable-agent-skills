---
trigger: model_decision
description: "Use when building or restyling a user interface, component, or page."
---


# Frontend design

## Design systems are not optional

If the project has a component library or token set, use it. Inventing around
one is the most common way generated UI ends up looking wrong in a codebase that
already has an answer.

```sh
ls src/components/ui 2>/dev/null        # shadcn, or a local set
grep -rn "tailwind.config" -l .          # tokens defined here
cat src/styles/tokens.css 2>/dev/null | head -40
```

When a token exists, use it. `bg-[#3b82f6]` beside a palette in `tokens.css` is
the defect, and it is one a design system is meant to make impossible.

## Scale before decoration

Most UI looks unconsidered because spacing and type are arbitrary. Establish the
scale first; colour and radius cannot rescue it.

**Type** as a modular scale, about 1.2–1.25 ratio. Body text 16px minimum, 18px
for long reading. Never below 14px for UI text. Set line height by measure: about
45–75 characters per line for body copy, which means `max-width: 65ch` rather
than an arbitrary pixel width.

**Spacing** on a 4px grid: 4, 8, 12, 16, 24, 32, 48, 64, 96. Every margin and
padding comes from this set. The discipline is the point, not the specific
numbers.

**Spacing is relational.** A component's internal gaps are its own scale; the gap
between components is one or two steps larger. Uniform internal spacing across
different components is what makes a layout read as arbitrary.

## Colour as roles, not values

```css
:root {
  --surface: hsl(0 0% 100%);
  --surface-raised: hsl(0 0% 98%);
  --text-primary: hsl(222 47% 11%);
  --text-secondary: hsl(215 16% 47%);
  --border: hsl(214 32% 91%);
  --accent: hsl(221 83% 53%);
  --danger: hsl(0 72% 51%);
  --success: hsl(142 71% 45%);
}
```

Semantic names mean a dark theme is a second value set, not a second stylesheet.
They also mean `text-secondary` stays consistent; a raw `#94a3b8` in three files
does not.

Check contrast in both themes. Body text needs 4.5:1; large text and UI
boundaries need 3:1. Material's 500-weight grey on white is about 4.6:1 and
700 is about 8:1, which is why so many default greys fail.

Do not encode meaning in hue alone. A red field and a green field are
indistinguishable to a reader with deuteranopia, and status needs an icon or a
word as well.

## Radius and elevation as a system

Pick two radii, not one: a small one for inputs and buttons, a larger one for
cards and modals. Pick one shadow style and one border colour. The goal is that
every elevation step is predictable, which is why arbitrary shadow values are
the thing to grep for:

```sh
grep -rnoE 'shadow-\[|rounded-\[[0-9]+px' src/ | head
```

## Ship the states, not just the default

The default state is the easy one. These are what make a component finished, and
they are the states that get skipped:

- **Loading** — skeleton matching the final layout, not a spinner over a blank
  page. The skeleton prevents the layout jump when content arrives.
- **Empty** — say what goes here and give the action that fills it. An empty
  screen with no explanation reads as broken.
- **Error** — say what failed and what to do. An error that only says "Something
  went wrong" transfers the diagnosis to the user.
- **Too much content** — a long name, a translated string, a 400-character value.
  Test with deliberately absurd content.
- **Disabled** — with a reason. A control the user cannot use and cannot
  understand is worse than one that explains itself.
- **Hover, focus, active.** Focus must be visible, which is separate from hover
  and frequently missing.

## Responsive behaviour is not a media query

- Content-driven breakpoints, not device names. Break when the layout breaks,
  which you find by narrowing the window, not by assuming 768px.
- Test 320px, not 375px. 320 is the narrowest phone still in use and it is where
  fixed padding fails first.
- Use `clamp()` for fluid type and spacing so it scales without jump points:
  `clamp(1rem, 0.9rem + 0.5vw, 1.25rem)`.
- Let flex and grid shrink. `min-width: 0` on a flex child is what stops a long
  unbroken string from blowing out the layout.
- Touch targets are 44 by 44 CSS pixels minimum, with space between adjacent
  ones, or thumbs miss.

## Animations

200ms for transitions, 300ms for entrances, with ease-out. Longer reads as
sluggish. Animate `transform` and `opacity`; animating `width`, `height`, or
`top` triggers layout on every frame.

Respect the setting:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

Motion is a vestibular trigger for some readers, and this is three lines.

## Before calling it done

- Keyboard through the whole flow. Tab order follows the DOM, and if the DOM
  order is wrong the tab order is wrong.
- Narrow to 320px and look for overflow.
- Zoom to 200% and confirm nothing is clipped.
- Replace real content with a very long string and re-check.
- Run an automated accessibility audit, then check what it cannot check.
