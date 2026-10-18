---
trigger: model_decision
description: "Use when reviewing UI code against interface guidelines, or when a question involves accessibility, layout, interaction, or UX quality."
---


# Web design guidelines

## Separate what is measurable from what is a judgement

A review that mixes `contrast is 3.1:1` with `the layout feels cramped` gets
treated as opinion throughout. Report them in separate sections, and use a
number for everything that has one.

## Objective findings

Check these against thresholds, not impressions.

**Target size.** Interactive elements need at least 44 by 44 CSS pixels, and
adjacent targets need spacing so the gap does not cause mis-taps.

```sh
grep -rnoE 'padding: [0-9]px|padding: [0-9]|gap: [0-9]' src/components | head
```

**Contrast.** 4.5:1 for body text, 3:1 for large text (18.66px bold or 24px) and
for UI component boundaries such as input borders and focus rings. Placeholder
text is frequently below 4.5:1 because it is styled like disabled text.

**Zoom and reflow.** At 400% zoom, or a 320px viewport, content must reflow with
no horizontal scrolling and no loss of function. `user-scalable=no` in the
viewport meta tag breaks this outright, and it is still common.

```sh
grep -rn "user-scalable\|maximum-scale" src/
```

**Focus visibility.** The focus indicator needs at least 3:1 contrast against
adjacent colours. `outline: none` with no replacement is the most frequent
finding in a UI codebase:

```sh
grep -rn "outline:\s*none\|outline:\s*0" src/
```

**Form labelling.** Every control needs an accessible name. `placeholder` is not
a label: it disappears on input and often fails contrast.

```sh
grep -rn "<input" src/ | grep -v "aria-label\|id=\|<label"
```

**Motion.** `prefers-reduced-motion` must be honoured for anything that moves,
including parallax and autoplay.

**Target size and spacing on the 320px layout.** Long unbroken strings without
`min-width: 0` on the flex parent, and tables without a scroll container, both
overflow here.

## Judgement findings

These have no threshold. State them as questions with a reason, not as defects.

- **Density.** Is there more on screen than the task requires? Can secondary
  information move to a detail view?
- **Hierarchy.** Can you tell the primary action without reading? If three
  controls look equally prominent, there is no primary action.
- **Feedback latency.** Does a click produce a visible response within 100ms?
  Perceived performance is a design property.
- **Recovery.** After a mistake, is there a clear way back? Undo beats
  confirmation dialogs, and a dialog asking "are you sure" usually means the
  action should be undoable instead.
- **Consistency.** Does the same word mean the same thing everywhere? A "Close"
  button in one modal and "Cancel" in another, both doing the same thing, is a
  real defect.

## The most common defects worth checking first

Ranked by how often they appear in real review:

1. A clickable `div` with no `role`, no `tabindex`, and no key handler.
2. A modal that does not move focus in, does not trap it, and does not restore
   it on close.
3. `outline: none` with nothing replacing it.
4. Icon-only buttons with no accessible name.
5. Fixed pixel widths that overflow at 320px.
6. `text-transform: uppercase` on body text, which destroys the word shape and
   hurts readability for dyslexic readers.
7. Disabled buttons used instead of validation messages, so the user finds out
   why only after clicking.
8. Placeholder text used as a label.
9. Loading states that block the whole page for one component.
10. Toast errors that vanish before they can be read or copied.

## How to report

For each finding, give the file and line, the threshold or the reason, and the
smallest fix. Rank by user impact, not by how easy the fix is.

Distinguish severity honestly. A missing form label is a blocker for a
screen-reader user. A card radius inconsistency is a note. Presenting them in one
undifferentiated list makes the blockers invisible.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The design already covers this." | Existing code has defects. The design is the intent, not the evidence. |
| "It looks fine to me." | You are not a screen reader, and you are not on a phone at 320px. |
| "I will fix accessibility later." | Later is after it ships, and it is the one class of defect users cannot work around. |
| "The audit tool says it is fine." | Automated tools catch roughly a third of accessibility issues. Keyboard and screen-reader passes catch the rest. |
| "It is only a prototype." | Prototypes get built, and they get built from. |
