---
description: "Use when a mobile app is slow to start, janky to scroll, or rejected by review."
---


# Mobile performance and release

## Scroll performance: fix the list before the framework

Most jank on a long screen is a list configured as if rows were free.

```jsx
<FlashList
  data={items}
  renderItem={renderItem}
  keyExtractor={item => item.id}
  getItemLayout={(_, index) => ({ length: ROW_H, offset: ROW_H * index, index })}
/>
```

- **`keyExtractor` is not optional.** The default uses `item.key` or the index.
  An index key means inserting a row re-renders every row after it, and reusing
  the row means state moves between items.
- **`getItemLayout` is the single highest-impact option** when row height is
  fixed. It tells the list the offset without measuring, which removes the
  measurement pass from scroll.
- Virtualised list tuning, when the framework offers it: `initialNumToRender`
  around 10, `maxToRenderPerBatch` around 5, a `windowSize` of about 21, and
  `removeClippedSubviews` on Android.

Swap to a dedicated virtualised list before micro-tuning a built-in one. The
architecture change beats every configuration flag.

## Re-renders come from three places

1. **Inline objects and inline callbacks as props.** `style={{padding: 8}}` and
   `onPress={() => set(x)}` create a new value every render, so memoised children
   never hit.
2. **Unmemoised context providers.** A provider whose value changes re-renders
   everything below it, whether or not they read the context.
3. **State updates to a parent list.** Adding an item to list state re-renders
   every already-rendered row, because React reconciles the state, not the rows.

Fix the third by keeping list item state inside the item and lifting only what
must be shared.

## Startup time

Measure time to interactive on a mid-tier device, not a flagship, and set a
budget. Typical targets worth holding: under two seconds cold start on a
mid-tier Android device, under about 1.2 seconds on a comparable recent iPhone.

What actually moves the number, in order of impact:

- **Lazy-initialise native modules** that are not needed on first paint. A module
  that costs 200ms to initialise and is used on one screen should not block
  launch.
- **Reduce the bundle executed before first render.** Anything initialised at
  module scope runs during startup whether or not it is used yet.
- **Defer non-critical work** to after first paint, not to a timer you hope is
  long enough.

Claimed improvements from a native-module architecture migration are large and
come from vendors. Treat them as directional and measure your own app.

## Accessibility: the numbers differ per platform

| | Android | iOS |
| --- | --- | --- |
| Minimum touch target | **48 x 48 dp** | **44 x 44 pt** |
| Screen reader | TalkBack | VoiceOver |

```jsx
<Pressable
  accessible
  accessibilityRole="button"
  accessibilityLabel={`Delete ${item.name}`}
  onPress={() => remove(item.id)}
/>
```

- `accessibilityRole` and `accessibilityLabel` are what make the element
  announce correctly. A pressable without them is a mystery to a screen reader.
- Deeply nested pressables **block touch events on iOS**. Set `accessible={false}`
  on the outer container and `accessible={true}` on the control that is actually
  interactive.
- `accessibilityLiveRegion` is **Android only**. VoiceOver reads
  `accessibilityHint` after the label only when hints are enabled in its settings.
- Some accessibility actions are platform-specific: escape and magic-tap are
  iOS, while expand and collapse are Android. Assume an action works on neither
  until you have tested both.

## App store review

Two guideline families cause most rejections.

**App completeness.** A crash on the reviewer's device, a demo account that has
expired, or a core feature more than a few taps from launch. Reviewers spend
**minutes**, not hours, so anything requiring setup fails on time rather than on
quality.

**Generated or templated apps.** Guideline 4.2 treats apps produced by a
commercialised template or generation service as requiring submission directly by
the content provider. If you resell the same app to many clients, ship one binary
that presents a per-client entry point rather than many near-identical listings.

Also worth checking before submitting:

- **64-bit support.** A bundle without the 64-bit architecture is rejected
  outright.
- **Permissions are scrutinized by risk.** Coarse location where fine was
  requested, background location with no clear justification, and SMS or
  accessibility services are the ones that trigger questions.
- **The privacy declaration must match what you actually ship**, including SDKs
  added since the last submission.
- **Hidden keywords are read**, so competitor trademarks in metadata are a
  rejection risk even though users never see them.
- Wording such as "beta", "trial" or "test" in a production listing reads as an
  unfinished submission.

Run a preflight against the real device build, with the real account, on a
network that is not your own, immediately before submitting. Most rejections are
environmental and none of them would have appeared in your testing.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "The list is fine, the issue is the framework." | Check `keyExtractor` and `getItemLayout` before blaming the engine. |
| "Inline styles are cleaner." | A new object every render defeats memoisation on every child. |
| "We will optimise scroll later." | It is a one-line list configuration and a measurable frame time. |
| "One target size works on both platforms." | 48dp on Android, 44pt on iOS. Check per platform. |
| "We tested the submission build." | Test the uploaded artifact, on a clean account, off your own network. |
| "The listing looks fine in the portal." | Hidden keywords are read and are a common rejection cause. |
