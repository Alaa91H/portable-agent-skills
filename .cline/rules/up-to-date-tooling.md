---
description: "Use when choosing a library or API, recalling a version, or adopting new tooling."
---


# Up-to-date tooling

## Your knowledge has a cutoff and the world did not

This is the one asymmetry you cannot reason your way out of. You can be extremely
careful, methodical and well-informed and still be wrong about a flag that was
renamed eight months ago — with total confidence, because recall does not feel
differently from recall.

So the discipline is not "know more current things". It is **"check the current
thing instead of recalling it"**. A version check is one command. Being wrong
costs a debugging session that starts with a symptom nobody can explain.

## The resolution order

When a fact depends on which version is in play, take it from the highest source
that can answer it. This is not a preference; the lower rows are *worse than
useless* in the specific way that they are confidently wrong.

| # | Source | Why it wins |
| --- | --- | --- |
| 1 | **The lockfile** | The only statement of what is actually installed |
| 2 | **The installed package** — its types, exports, source | Describes the code that will run, not a description of it |
| 3 | **Docs for that version**, not the latest | Latest docs describe a version you may not have |
| 4 | **The changelog**, for recent changes | Tells you what moved and when |
| 5 | **Your prior** | Last, and always labelled |

The lockfile beats `package.json` ranges, because a range is an intention and a
lockfile is a fact. And the installed package beats both, because it is the only
one that cannot be wrong about what will run.

```bash
# 1 and 2, mechanically
node -p "require('./node_modules/vitest/package.json').version"
grep -rn "export.*defineConfig" node_modules/vitest/dist/*.d.ts | head

# 3, when the installed package is not enough
npm view <pkg> dist-tags versions --json

# 4, for what changed recently
npm view <pkg> time --json | tail -20
```

## Never state a version or signature from memory when you can check

Version-specific facts are the highest-risk content you produce, because fluency
is highest exactly there. A function name you are sure about has the greatest
chance of being the name it had two majors ago.

| Recall is fine for | Recall is not fine for |
| --- | --- |
| Language semantics | Whether a library accepts an argument |
| Algorithmic tradeoffs | A current parameter name |
| Design principles | The latest major version of a tool |
| When something is a bad idea | That a config key exists |
| Broad architecture | The exact spelling of a flag |

The dividing line is simple: **if a wrong answer would compile or run, check it.**

## Check the version you are on, not the latest one

An API can be deprecated and still work, removed and gone, or renamed while a
compatibility alias keeps both alive. Only the version in your lockfile decides
which you have.

```bash
# what am I actually pinned to
grep -A2 '"express"' package-lock.json | head -5

# what does this specific installed build export
cat node_modules/<pkg>/package.json | grep -E '"version"|"exports"' -A4
```

Adapting to the latest API when the project is pinned two majors back is not
modern, it is broken. **Modern means correct for this version**, which is a
different and less glamorous claim.

## Do not upgrade as a side effect of a fix

This is where "always use the latest" causes real damage.

- **Fix the bug on the pinned version.** A minimal diff on a known-good
  dependency is reviewable, bisectable, and revertible.
- **Upgrade deliberately**, as its own change, with its own review and its own
  test run.
- **Never widen a lockfile inside a bugfix commit.** It makes the diff
  unreviewable, because no reviewer can tell which line broke the behaviour.

The worst outcome is a bugfix that also pulled eleven transitive updates and now
fails for a reason nobody can localise.

## New is not better

Adopting something for a reason you can state is engineering. Adopting it because
it is newer is fashion, and fashion in dependencies is how projects end up with a
migration they cannot afford.

Before adopting, be able to answer:

1. What problem does this solve that the current approach does not?
2. Is it stable, and what is its support story?
3. What is the migration cost, and who pays it?
4. What does it displace, and is the alternative still maintained?

```
Adopt because: the current package is unmaintained since 2024 and has two open
               security advisories with no fix scheduled.
Reject because: newer, and we have no problem the change would solve.
```

An unmaintained dependency is a real reason. Novelty is not.

## Know what changed recently in the ecosystem you use

You do not need to track everything. You need to track the handful you actually
use, which is a small, checkable set.

- Pin a short list of dependencies whose recent changes could affect you
- Read the changelog when the pinned version is less than a year old
- Subscribe to the breaking-change notices of the two or three libraries that
  would hurt most to be wrong about

Concretely, per project:

```
# what is old enough that its docs have moved on
npm outdated

# what would a major bump actually change
npm view <pkg>@latest readme | head -40
```

## Verify against the type system when you can

Types are the cheapest available check on whether an API is as you remember it,
and they are mechanical rather than a matter of confidence.

```ts
import { defineConfig } from 'vitest/config'
```

If the signature does not match, the compiler says so in seconds. If it does
match, you had a real answer rather than a feeling about one. When the package
ships types, prefer reading them over reading the documentation — see
`hallucination-defense` for the grounding rule this supports.

## Label every version claim in output

```
The config option is `testTimeout` in vitest 1.x. I have not verified the
version pinned here — check package-lock.json before relying on it.
```

If you have checked, say so and say how:

```
`testTimeout` is correct for the pinned vitest 2.1.4 (src: vitest/dist/node.d.ts:88).
```

The difference between those two lines is the difference between output a reader
can act on and output they have to re-derive.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I know this library well." | You know the version you learned. Not the one installed. |
| "The latest docs say so." | The latest docs describe the latest version. Check what you have. |
| "I will bump the lockfile while I am here." | Then no reviewer can tell which line broke it. |
| "Newer is better." | Newer is a reason to look, not a reason to adopt. |
| "It is a well-established library." | Established is not the same as unchanged. |
| "I will verify later." | Later is after the wrong code has been written against it. |
| "The docs are for the current major." | Usually. The pin is what makes it current, not the docs. |
