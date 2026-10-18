# Essential Agent Skills

A curated, validated collection of **79 agent skills** covering the full arc of
software work: deciding what to build, building it test-first, getting it
reviewed, shipping it, running it, operating it, and writing skills of its own.

Every skill is written to the open [Agent Skills
specification](https://agentskills.io/specification), enforced by a validator in
this repository, and mirrored into every agent discovery convention so it works
with any agent out of the box.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git && cd portable-agent-skills && ./install.sh
```

Current release: **1.1.0** · 79 skills · 18 domains · 14 agents · MIT

Every day the [daily workflow](.github/workflows/daily.yml) re-verifies the
collection, rebuilds the catalog, and watches the upstream specification for
drift. Every release carries English notes in
[`CHANGELOG.md`](CHANGELOG.md); see [Keeping it current](#keeping-it-current).

---

## Contents

- [Why this collection exists](#why-this-collection-exists)
- [Quick start](#quick-start)
- [Reading this in your language](#reading-this-in-your-language)
- [Platform support](#platform-support-stated-rather-than-claimed)
- [Keeping it current](#keeping-it-current)
- [Supported agents and protocols](#supported-agents-and-protocols)
- [How discovery works](#how-discovery-works)
- [The collection](#the-collection)
- [Design rules](#design-rules)
- [Repository layout](#repository-layout)
- [Tooling](#tooling)
- [Contributing](#contributing)
- [License](#license)

---

## Why this collection exists

Research into the existing ecosystem produced findings that shaped everything
here. Two of them were surprises that cost real skills.

**The saturated niche is the obvious one.** Of the 149 most-installed skills ever
published, about 44% are engineering-process meta-skills: planning, TDD,
debugging, code review. That niche is crowded. Meanwhile DevOps, backend design,
data engineering, infrastructure as code, authentication implementation, Linux
operations, email deliverability and search have either **no registry taxonomy
at all** or around thirty official vendor skills sitting at **zero installs**.
Auth0 ships fourteen authentication skills and not one has been installed.
HashiCorp ships eleven Terraform skills, all at zero. Stripe ships two, both at
zero. And **date and time handling has no skill anywhere in the world**, in one
of the most bug-dense domains there is.

**Two agents silently drop skills that do not fit.** Codex gives the skill list
**8,000 characters** and truncates descriptions, omitting skills that overflow.
Zed caps the same content at 50 KB. An earlier revision of this collection was
already at 97% of the Codex limit, so skills were being lost there with no
error at all. The validator now measures both budgets, and every description was
rewritten to a uniform 80 to 110 characters to create room to grow.

**A description that summarises the workflow is actively harmful.** The
`superpowers` collection documented an agent following a plan taken from a
description and performing one code review where the body clearly specified two.
The body became documentation nobody read. Every description here describes the
*trigger surface* and never the procedure.

**Guidance should match the failure.** Prohibitions work when a rule is being
rationalised away under pressure. For output with the wrong shape, prohibitions
measurably produced *more* unwanted content than an equivalent positive recipe.
`writing-agent-skills` carries the full table.

Finally, nothing mechanically checkable is written down. Where a rule could be a
lint, a CI gate or a validator, this repository enforces it instead.

---

## Quick start

```sh
# OpenCode picks up ./skills and ./.opencode/skills via opencode.jsonc
opencode

# Claude Code picks up ./.claude/skills
claude

# Codex, Cline, Kilo, Amp, Zed, Goose, Gemini CLI, Augment, Roo, Cursor,
# Copilot, Junie, Devin and roughly twenty more read ./.agents/skills
```

Install into your user-level directory so they apply to every project:

```sh
./install.sh                      # list all 14 supported agents and status
./install.sh opencode --global    # install for the current user
./install.sh agents --global      # serves roughly two dozen agents at once
./install.sh claude --global

./install.sh --list               # every available skill id
./install.sh opencode --only sql-query-performance,systematic-debugging
./install.sh opencode --uninstall
```

Serve them to an agent that supports a remote catalog:

```sh
scripts/build-catalog.sh          # emits dist/index.json with descriptions
```

Or through the community registry:

```sh
npx skills add Alaa91H/portable-agent-skills          # project scope
npx skills add Alaa91H/portable-agent-skills -g       # global scope
```

Install as a Claude Code plugin:

```text
/plugin marketplace add Alaa91H/portable-agent-skills
/plugin install essential-skills@essential-agent-skills
```

Validate against the open specification:

```sh
skills-ref validate .opencode/skills/systematic-debugging
```

---

---

## Reading this in your language

The skills are English on purpose, because an agent routes on `name` and
`description` and identical routing fields in every language is what makes the
collection work no matter what you write in. Everything a *reader* needs is
translated:

| | | | |
| --- | --- | --- | --- |
| [English](README.md) | [Español](docs/i18n/es.md) | [Français](docs/i18n/fr.md) | [Deutsch](docs/i18n/de.md) |
| [Português (BR)](docs/i18n/pt-BR.md) | [简体中文](docs/i18n/zh.md) | [日本語](docs/i18n/ja.md) | [Русский](docs/i18n/ru.md) |
| [العربية](docs/i18n/ar.md) | | | |

`scripts/check-i18n.sh` verifies that every translation lists the same domains as
`skills.sh.json` and the same skill count, so a translation cannot silently fall
behind the collection. Adding a language is a new file plus one line in
[`docs/i18n/README.md`](docs/i18n/README.md), with no code change.

## Platform support, stated rather than claimed

[`docs/platforms.md`](docs/platforms.md) separates what is **verified** from what
is **structural** from what is **not true yet**, including the distribution
channels that are real, the one MCP claim this repository deliberately does not
make because it described a resource removed before the specification was final,
and the five platform-specific defects this repository shipped and could not see
from the platform it was written on.

The short version: the **skills** are platform-independent by construction,
because they are Markdown files with no runtime. The **tooling** is not, and that
is where the differences are documented.

## Keeping it current

A collection that stops updating stops being a reference. Three mechanisms keep
this one current, and each answers a different question: what changed, how do I
get it, and has the ground moved underneath us?

### What changed

Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and
are recorded in [`VERSION`](VERSION). Notes are in
[`CHANGELOG.md`](CHANGELOG.md), in
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

A version covers the **collection**, not the tooling separately. Adding a skill,
rewording a routing sentence, and changing the validator are all the same kind
of event to a consumer, because all three change which skills reach them.

Cut a release with:

```sh
scripts/release.sh 1.2.0            # run every gate, then commit and tag
scripts/release.sh 1.2.0 --dry-run  # run every gate, change nothing
```

The script refuses to cut a release unless all seven gates pass and
`CHANGELOG.md` already has a section for the version. A tag can therefore never
point at a collection that does not validate.

The release workflow publishes on the tag, and re-checks two things that are the
most common release mistakes:

- **the tag matches `VERSION`**, so you cannot bump one and tag the other;
- **the tag is reachable from `main`**, so a side branch cannot publish a
  collection that never passed CI on main.

It then attaches a signed tarball of the canonical source, its SHA-256 sums, the
catalog, and a machine-readable update manifest.

### How to get it

For a checkout, the update is one command:

```sh
./install.sh --update                 # refresh the source, report what changed
./install.sh --update opencode --global   # refresh, then reinstall
```

`--update` pulls from `origin`, then reports the version transition, any change in
skill count, and the new release notes pulled from the changelog. It deliberately
does **not** regenerate the mirrors: every mirror in this repository is a
committed artifact produced by CI and gated by a `--check` test, so a pull
already brings the regenerated ones with it.

For anything that wants to poll rather than pull, the rolling release keeps a
single stable URL. `update-manifest.json` is small and stable, so a poller can
cache it cheaply and re-fetch only when something changed:

```json
{
  "collectionVersion": "1.1.0",
  "catalogVersion": 7,
  "commit": "7e7eb76",
  "builtAt": "2026-10-18T03:57:06Z",
  "skillCount": 67,
  "digest": "13c5cdfbee097757",
  "index": "index.json"
}
```

Two version numbers appear there deliberately, and conflating them is a real
bug. `collectionVersion` is the product version and changes only when a release is
cut. `catalogVersion` is a **cache key** that changes whenever any file changes,
because hosts key their catalog cache on it — using the semver alone would serve
a stale catalog after every skill edit that did not come with a release, which
is most of them.

### Has the ground moved

Every day the [`daily`](.github/workflows/daily.yml) workflow runs three jobs:
verification, a rolling catalog build, and a check for drift in the upstream
[Agent Skills specification](https://agentskills.io/specification).

That last one is the reason this repository fingerprints its upstream. A
collection is only as conformant as the specification it was written to, and
that specification can change underneath it. Learning months later from a failing
validator is the worst way to find out, because every skill in the collection may
already be non-conformant at the same moment. The fingerprint is a hash of the
specification body, so the check is cheap and cannot report a false positive from
formatting.

Drift opens an issue. It does not fail the build, and it should not: nothing is
broken, and a check that cries wolf gets ignored.

```sh
scripts/check-upstream.sh            # report drift, change nothing
scripts/check-upstream.sh --accept   # record the current fingerprint
scripts/check-upstream.sh --status   # print what is on record

scripts/check-i18n.sh                # verify every translation matches the collection
```

Read the specification diff before accepting a new fingerprint. The fingerprint is
what stops the check reporting again, so accepting it early silences the signal
permanently.

---

## Supported agents and protocols

### Native skill discovery (progressive disclosure)

| Agent | Project path | User path |
| --- | --- | --- |
| OpenCode | `.opencode/skills`, `skills` | `~/.config/opencode/skills` |
| Claude Code | `.claude/skills` | `~/.claude/skills` |
| **Spec clients** — Codex, Cline, Kilo, Amp, Zed, Goose, Gemini CLI, Augment, Roo, Cursor, Copilot, Junie, Devin, Trae, Qodo | `.agents/skills` | `~/.agents/skills` |
| GitHub Copilot | `.github/skills` | `~/.github/skills` |
| Cursor | `.cursor/skills` | `~/.cursor/skills` |
| Windsurf / Devin Desktop | `.devin/skills` | `~/.codeium/windsurf/skills` |
| Cline | `.cline/skills` | `~/.cline/skills` |
| Roo Code | `.roo/skills` | `~/.roo/skills` |
| JetBrains Junie | `.junie/skills` | `~/.junie/skills` |
| Kilo Code | `.kilo/skills` | `~/.kilo/skills` |
| Trae | `.trae/skills` | `~/.trae/skills` |
| Augment | `.augment/skills` | `~/.augment/skills` |
| Gemini CLI | `.gemini/skills` | `~/.gemini/skills` |
| OpenAI Codex CLI | `.codex/skills` | `~/.codex/skills` |
| Catalog-capable agent | `dist/index.json` over HTTP | served URL |

`.agents/skills/` is the highest-leverage single path in the ecosystem: roughly
two dozen agents read it natively.

### Flat instruction files

Some agents cannot mount a skills directory, so `scripts/sync-rules.sh`
generates what they can consume from the same source.

| Agent | Generated path | Mode |
| --- | --- | --- |
| Cursor | `.cursor/rules/*.mdc` | On demand, `alwaysApply: false` |
| Windsurf / Devin | `.devin/rules/*.md`, `.windsurf/rules/*.md` | `trigger: model_decision` |
| Roo Code | `.roo/rules/*.md` | On demand |
| Cline, Trae | `.cline/rules/*.md`, `.trae/rules/*.md` | On demand |
| Cline (legacy), Continue, Goose, Zed, Amazon Q, Augment | one index file per agent | Pointer only |
| ~25 tools incl. Codex, Cursor, Copilot, Gemini, GitLab Duo, JetBrains | `AGENTS.md` | Pointer only |
| Aider | `.aider.conf.yml` with `read: [AGENTS.md]` | Opt-in; Aider has no discovery |

On-demand agents get the full body with their own frontmatter, which reproduces
progressive disclosure. Agents that always load every rule get a single pointer
file instead, because 59 full bodies would overflow their context.

### Remote catalog formats, and what is actually real

There are **three competing `index.json` shapes** in circulation under similar
names, and they are not compatible:

| Mechanism | Location | Entry shape | Status |
| --- | --- | --- | --- |
| Kilo Code `skills.urls` | `<base>/index.json` | `{name, version, files[]}` | **Widely implemented.** This is what `dist/` emits |
| Cloudflare discovery draft v0.2.0 | `/.well-known/agent-skills/index.json` | `{name, type, url, digest}` | Draft, not ratified, negligible adoption |
| MCP Skills extension | **not a file** | `skills/list` and `skills/get` RPC methods | Spec final Sept 2026, no official SDK support yet |

**A correction worth stating plainly**: an earlier version of this README
described `dist/index.json` as satisfying the MCP skills extension via
`skill://index.json`. That is wrong. The `skill://index.json` discovery resource
existed only in a pre-final draft and was **removed** from the final
specification, which uses RPC methods instead. `dist/index.json` is a
filesystem-style catalog for agents that fetch one; it is not an MCP catalog.

### Other protocols

- **Plugin marketplace.** `.claude-plugin/marketplace.json`.
- **skills.sh registry.** `skills.sh.json` declares the groupings.
- **ACP.** The editor-to-agent protocol defines **no skills convention at all**,
  so this collection makes no ACP-specific claim.

### Two constraints that decide whether your skills appear at all

| Agent | Budget | What happens on overflow |
| --- | --- | --- |
| Codex | **8,000 characters** of name plus description | Descriptions shortened, then skills omitted with a warning |
| Zed | 50 KB of the same | Skills dropped from the catalog |

Both are enforced by `scripts/validate-skills.sh`. Zed also does not discover
nested skill folders, which is why the layout here is flat.

---

## How discovery works

An agent cannot use a skill it cannot find, and each convention expects
`SKILL.md` in a particular directory. There is exactly one source of truth.

```
.opencode/skills/<skill-id>/SKILL.md      canonical, 59 skills
```

Generated by `scripts/sync-agents.sh`:

```
skills/<skill-id>/SKILL.md                spec layout, plugin root, GitLab Duo
.claude/ .agents/ .github/ .cursor/ .devin/ .cline/
```

Generated by `scripts/sync-rules.sh`:

```
.cursor/rules/*.mdc                       full body, agentic
.roo/rules/*.md  .windsurf/rules/*.md  .devin/rules/*.md  .cline/rules/*.md  .trae/rules/*.md
.clinerules/agent-skills.md              index, for always-loaded rule engines
AGENTS.md  GEMINI.md  CONVENTIONS.md  CLAUDE.md  .cursorrules  AmazonQ.md  TABNINE.md
.aider.conf.yml
```

Generated by `scripts/build-catalog.sh`: `dist/index.json` plus `dist/<skill-id>/`.

Everything is committed, so a fresh clone works with any agent without a build
step. Each generator has a `--check` mode that CI runs. **Mirror verification
compares file content, not names**, because a name-only check would pass while a
rule exists in one mirror and not another, which is the failure mode reported
against `cp -r`-based distributions.

### The three levels of disclosure

1. **Metadata**, about 100 tokens. `name` and `description`, in context at every
   step for every installed skill.
2. **Instructions**, under 5k tokens. The body, read once when the skill triggers.
3. **Resources**, unbounded. `references/`, `scripts/`, `assets/`.

`writing-agent-skills` applies this to itself: its long material sits in
`references/` while the body stays a tight operating procedure.

---

## The collection

### Craft and process

**`planning-before-implementation`** — Decides whether a change is worth planning
and makes the plan checkable. A plan is a list of **states**, not activities:
"reject requests missing `owner_id` with 400 before any query runs, covered by a
test that fails without the check" is verifiable; "add validation" is not.
Prefers decomposition at running seams and vertical slices, because a horizontal
slice leaves nothing working until its final line.

**`writing-acceptance-criteria`** — Turns a vague request into statements two
people could disagree about, which is the actual test of completeness. Covers the
six cases that generate disagreement (empty, boundary, malformed, duplicate,
concurrent, partial failure), argues for explicit non-goals as the
highest-value line in the document, and insists on asking **one** question with a
stated default rather than five open ones.

**`test-driven-development`** — The red-green-refactor loop with the part most
write-ups omit: a test must fail **for the reason you expect**, or it has not
tested anything. Treats a test that is hard to write as a design signal. For
bugs, the failing test is the reproduction and is non-negotiable.

**`systematic-debugging`** — Refuses any code change before there is a hypothesis
that can be disproved, because editing to "see what happens" destroys the
evidence while leaving the defect. Includes a table distinguishing
`ECONNREFUSED` from `ETIMEDOUT` from `ENOTFOUND`, because an error seen before
still fails for a new reason.

**`verification-before-completion`** — Evidence before assertion, with a mapping
from each claim to the command that would falsify it. Gives most attention to
**negative** claims, where nothing fails if you skip. Distinguishes exit code
zero from a genuinely passing run.

**`completeness-and-detail`** — The miss is almost never a hard thing; it is a
boring adjacent one, so the method is to **enumerate before you act** and only
then choose what to do. An inventory you did not write down is an inventory you
did not have. Then **trace the lifecycle rather than the function** — create,
read, update, delete, serialize, export, audit — because `delete` and `export`
are where the surprise lives, since nobody was looking at them. Includes a
closure checklist per artifact type, the boundary states that get missed (empty,
one, maximum, concurrent, partial failure, unicode), and the highest-yield
command in the skill: grepping for every identifier and literal the diff deleted.
It also says where completeness **stops**, because an unstated boundary reads as
an oversight when someone finds it later.

### Testing and review

**`requesting-code-review`** — Makes the review possible first: the requester
states the problem, the approach, the rejected alternative, and what is out of
scope. Quantifies reviewability, because beyond roughly 800 changed lines
reviewers approve the shape rather than the logic.

**`receiving-code-review`** — Sorts every comment into correctness, contract,
maintainability or preference **before** acting, because acting in arrival order
gives a naming preference the same attention as a data-loss defect. Requires every
comment to end in one of three states, since "unaddressed" reads identically to
"missed".

**`property-based-testing`** — For the case where example tests are structurally
insufficient. Frames properties as invariants over the input space, warns that
random strings against a structured function waste the entire budget, and
explains that shrinking is the reason the technique is worth adopting.

**`webapp-testing`** — Driving a real browser without the flakiness that usually
comes with it. Wait for conditions and never for time, because a sleep passes on
an idle machine and reports load rather than the bug otherwise. Locates elements
by role and accessible name, and treats console errors and 4xx responses as
first-class signal.

**`contract-and-load-testing`** — Consumer-driven contracts with Pact, including
the rule that a contract must be the **loosest** one that still catches a
breaking change, and that provider verification belongs in a separate CI build so
one team cannot break another's pipeline. Then load testing with k6, where the
threshold aggregation method must match the metric type or the test fails to
parse, and a five-minute run cannot see a leak that takes an hour.

**`refactoring-without-breaking-behaviour`** — Behaviour must be pinned by a test
before structure changes. Small reversible steps, one rename or extract per
commit. Its most distinctive advice is to **delete more often than extract**, with
guidance on telling genuine duplication from blocks that differ in strategy.

### Working in a codebase

**`onboarding-unfamiliar-codebase`** — Orientation before reading. Recent churn
and **co-change frequency** predict relevance far better than directory names:
files that always change together are one concept whatever the layout says. Read
tests before production code, because they are the specification and they are
honest, since they fail when behaviour breaks.

**`environment-bootstrap`** — The output of a successful bootstrap is the
highest-value artefact a contributor produces. Install from the lockfile, check
declared runtime versions before dependencies, verify each service is actually
healthy rather than merely started, and **run the test suite before writing any
code** so a broken environment is distinguished from your own changes.

**`domain-modeling`** — Start from the vocabulary, not the schema. A disagreement
about a word is a disagreement about the model, and it is far cheaper to find now
than after three teams implement incompatible meanings of "order status".
Separates entity states that are genuinely different, and pushes behaviour into
the model so a rule is written once.

**`improving-codebase-architecture`** — Demands evidence before proposing
structure. Looks for four specific findings rather than offering a general
critique, separates structural from style findings because bundling them makes
the structural ones harder to approve, and refuses the rewrite unless the
evidence is enumerable.

**`writing-technical-docs`** — Distinguishes the three genres, because mixing them
produces a document serving nobody. Its central principle is to document the
**decision**, not the code. Prefers executable documentation, mapping things
people write down to things that should be generated or tested.

**`codebase-decomposition`** — **File size is a symptom; the disease is unrelated
reasons to change.** The real test is countable: how many distinct reasons are
there to open this file in a year. It provides the command to count them, and the
rule that a 900-line file with one reason to change is fine while a 200-line file
with three is worse, because every unrelated edit risks a conflict. Then the
distinction that actually decides the split: **group by change axis, not by noun**.
`models/` and `services/` and `handlers/` scatter one feature across six folders;
one directory per feature makes a change touch one path.

**`up-to-date-tooling`** — The asymmetry you cannot reason your way out of: your
knowledge has a cutoff and the world did not, and recall of a version-specific
fact feels exactly like certainty. So the discipline is not knowing more, it is
**checking instead of recalling** — a resolution order from the lockfile down to
your own prior, which is always last and always labelled. Contains the dividing
line: *if a wrong answer would compile or run, check it.* And the rule that
prevents the worst outcome: **never widen a lockfile inside a bugfix**, because
then no reviewer can tell which line broke it.

### Version control

**`using-git-worktrees`** — When a second working directory is genuinely right and
when it is overhead. Its most valuable section is the trap: a worktree has **no
dependencies of its own**, so it needs its own install, and two worktrees sharing
a build directory will corrupt each other's output.

**`git-internals`** — The reflog is your undo: `reset --hard` looks absolute and
is not, and the commit is still there. Automate bisect with `git bisect run
<test>` or you are the loop and you stop after ten steps. Hooks do not travel
unless you commit them and set `core.hooksPath`, and a submodule is a **pointer**,
so a change inside it is invisible to the parent until you stage the submodule
path — the usual cause of green locally and broken in CI.

**`finishing-a-development-branch`** — An ordered procedure, because skipping
ahead is how branches reach main with a failing test. Runs the install as well as
the suite, and reads the diff as a reviewer rather than as its author. Tabulates
squash versus merge versus rebase, and states that force-pushing a shared branch
is never acceptable.

**`resolving-merge-conflicts`** — A conflict is git saying it cannot decide
whether two changes are compatible. Establishes the three-way view, because
knowing which side is `HEAD` is the most commonly reversed fact, and shows
`--conflict=diff3` for revealing the base. Tabulates files that must never be
hand-resolved, such as lockfiles and generated clients.

### Interfaces and accessibility

**`frontend-design`** — Scale before decoration, since most unconvincing
interface work has arbitrary spacing and type rather than a colour problem. Gives
a modular type scale, a 4px spacing grid, and colour as semantic roles so dark
themes are a second value set. Its most practical section is the states: loading,
empty, error, too much content, disabled, focus.

**`css-architecture`** — Tokens first, then cascade layers. Layers remove the
reason people reached for CSS-in-JS: order is declared once, so a component does
not need `!important` or a naming scheme to win over a utility. Includes the
specificity-escalation arms race that layers replace, and container queries for
components that must work in a sidebar as well as a page.

**`web-design-guidelines`** — Separates measurable from judgement, because mixing
`contrast is 3.1:1` with `the layout feels cramped` gets everything dismissed as
opinion. Objective findings carry thresholds: 44 by 44 CSS pixel targets, 4.5:1
contrast, reflow at 320px or 400% zoom. Ranks the ten most common defects found
in real review.

**`accessibility-audit`** — A six-pass audit in dependency order, where a contrast
audit of a control that cannot be reached by keyboard is wasted effort. Its
strongest material is semantic: the cheapest accessibility work is deleting the
wrong element, and the correct version of a clickable `div` gets focusability,
role and key handling for free. Automated tools catch roughly a third.

**`localization-i18n`** — Never concatenate sentences, because word order differs
by language. Pluralisation belongs to the translation format, not to a ternary:
English has two forms and Arabic has six, so `n === 1` is wrong almost
everywhere. Includes the decimal-separator trap, where hard-coding `.` misprices
by a factor of a thousand in much of the world.

### APIs and integrations

**`rest-api-design`** — Error bodies are **RFC 9457 Problem Details**, not a
bespoke envelope, with four rules models break most: `status` is advisory and must
match the real HTTP status, `title` must not vary between occurrences, `detail`
is not machine-readable, and `type` must be an absolute URI because a relative
one resolves differently under different paths. Decides cursor versus offset
pagination before launch, because cursor cannot be retrofitted.

**`api-contract-versioning`** — Establishes whether you can break the API before
choosing a strategy. The checklist catches the non-obvious cases: adding an enum
value is breaking, adding an optional request field is breaking for strict
clients. Requires a machine-readable deprecation signal rather than a date in
prose.

**`graphql-api-security`** — N+1 as the default failure mode, invisible at five
posts and catastrophic at fifty thousand. Neither depth nor amount limiting is
built in, and they are two different attacks: a depth limit alone does not stop
`posts(first: 99999999)`. The distinction that matters most is that **persisted
queries are a performance feature, not a security control**, because APQ lets
anyone register a new query.

**`webhook-integration`** — Verifying a signature is the whole job, and four
details are skipped somewhere: verify **raw bytes** before parsing, compare in
**constant time**, enforce a **timestamp tolerance** against replay, and
acknowledge `2xx` before doing the work. Distinguishes duplicate delivery from
malicious replay.

**`oauth-authentication`** — OAuth 2.1 is a draft, not an RFC, and states that
precisely. PKCE mechanics with the actual character ranges. The rule assistants
get wrong: **a self-contained JWT cannot be revoked**, so "stateless" is exactly
what removes revocation, and first-party browser apps should use server-side
sessions.

**`payments-integration`** — Where real money is lost. Idempotency keys are
**pruned after 24 hours**, so a retry scheduled for tomorrow creates a second
charge; generate the key at send time, not at enqueue time. Webhook ordering is
not guaranteed, so refetch the live object rather than trusting the embedded
snapshot. And `invoice.payment_failed` does not mean cancelled: dunning is
running, and reading the resulting status is not the same as authoring the
transition yourself.

### Data and storage

**`sql-query-performance`** — Read the plan before changing anything, and what to
look for in it: rows estimated versus actual, a nested loop with a large outer
set, sort spill to disk, and the row-count explosion that is the real cause in
most bad plans. Sargable and non-sargable predicates side by side.

**`database-migrations`** — PostgreSQL's lock table, because `ALTER TABLE` takes
`ACCESS EXCLUSIVE` and that is why naive migrations take an application offline.
**Always set `lock_timeout`** so a migration fails fast instead of queueing behind
a long transaction. Expand and contract for anything breaking, with the reason
dropping a column in one deploy breaks rollback.

**`caching-and-stampedes`** — Computes the herd so it is concrete: 2,000 requests
per second on a 400ms query is 800 concurrent identical queries. Four defences in
order of effort, and the one people forget: **jitter is mandatory**, because fixed
TTLs synchronise every key created by the same deploy. Includes the `no-cache`
versus `no-store` distinction that causes real data leaks.

**`message-queue-processing`** — Exactly-once is a scoped claim usually oversold;
Kafka's own design documentation is quoted on the fine print and the three
possible commit orderings. Design for at-least-once plus idempotent consumers.
Ordering is per partition only, so key by entity id. Dead letter queue numbers
that are concrete: visibility timeout at least 6x the function timeout, and
`maxReceiveCount` at least 5.

### Data engineering

**`dbt-modeling`** — Three layers, and the naming makes intent obvious. The
incremental filter that is wrong most often is the one that omits the `coalesce`
sentinel, which silently reloads everything on an empty table. `unique_key` takes
column names, never an expression, and **NULLs in those columns break the merge**.
The `on_schema_change` default is `ignore`, which does not add columns at all.

**`dimensional-modeling`** — Surrogate keys come first, because the source
identifier changes on renumbering and breaks every historical join. **Grain is
decided once** and is where most fact-table errors come from. SCD type is chosen
**per attribute**, not per dimension, so one dimension routinely mixes Type 1, 2
and 3. Period snapshots are semi-additive, and summing them is a meaningful-looking
nonsense number.

**`orchestration-dag-authoring`** — The rule that catches everyone: the scheduler
re-executes all DAG code on an interval, so **any top-level database call fires
120 times an hour** regardless of how rarely the DAG runs. Treats tasks as
transactions: upsert rather than insert, and pin to `data_interval_start` rather
than to whatever is currently latest, or two runs of the same interval disagree.

**`spark-performance`** — Adaptive Query Execution is already on, and enabling it
can break `cache` reuse. Skew needs **two** conditions, not one, and a partition
at five times the median is not skewed unless it also exceeds the absolute
threshold. Skew optimisation does not apply to broadcast joins, nor to the right
side of a left outer join, nor to a full outer join at all.

### Infrastructure and operations

**`docker-containerization`** — Layer order is cache order, and this is the
single highest-leverage Docker rule. Covers cache mounts and the silent
misconfiguration where they never reach CI. The **PID 1 problem**: a process
without an init gets no default signal handlers, so `CMD ["npm", "start"]` kills
rather than shuts down.

**`kubernetes-deployment`** — **Liveness must never check a dependency**,
because a database hiccup then restarts every pod at once and the storm lands on
the database while it recovers. The startup probe formula: defaults give a
30-second budget, so any slower app is killed mid-boot. A CPU limit is a hard
stall at the quota boundary rather than smooth throttling, and the
`maxUnavailable` percentage-rounding trap catches teams at low replica counts.

**`infrastructure-as-code`** — State is the hard part: it holds secrets in
plaintext, must be backed up before every operation, and one state per
environment. The plan is the review artefact, rendered so a reviewer sees
**replacements and destroys**, which are invisible in the code diff.

**`ci-pipeline-security`** — Pin actions to a SHA **and verify the SHA is real**,
because GitHub runs a matching commit regardless of which fork it came from.
Explains why `pull_request_target` checking out pull request code is remote code
execution with production credentials, and why caching must be disabled in
release workflows.

**`linux-ops-debugging`** — The ordering that wastes the most time: check inodes
before space, because a full partition with free space means no inodes. A deleted
file whose descriptor is still open consumes space, does not appear in `du`, and
`lsof +L1` is the only way to find it. `ExecCondition` exit codes are asymmetric,
and `"$@"` versus `$*` destroys any argument containing a space.

**`incident-response`** — Mitigate first, diagnose second, because the fastest
correct action is almost always the one that undoes the most recent change. The
first fifteen minutes as a checklist, the separation of commander from operator,
updates on a timer even when there is no change. The postmortem is blameless for
people and factual for systems, because one that finds a person at fault has
found nothing.

### Platform operations

**`cloud-security-and-cost`** — Delegates application security elsewhere and
covers only cloud infrastructure. The permissions-boundary pattern for delegating
policy authoring without losing control, and the **confused deputy** condition
key, which is the most-missed line in resource-based policies. Presigned URLs
expire when the **credential** expires, not when the clock does, and provisioned
concurrency bills while idle from enable until disable.

**`feature-flag-and-secrets-lifecycle`** — Ten flags is **1,024 code paths**, which
is the argument for an expiry date at creation. The retirement order matters and
is counterintuitive: **remove the code before the flag**, because removing the
flag first deletes your visibility into its carrying cost. Some flags should
never expire. Secret rotation uses staged labels, and that staging is the entire
zero-downtime mechanism.

**`search-engineering`** — The 1,000-field limit is what fails first, and dynamic
mapping is what reaches it. `cross_fields` silently matches any single word
without `minimum_should_match`. `field_value_factor` needs `missing: 0` or
documents without the field error the query. Chunk overlap in retrieval is a
default to **measure**, not a law, since a systematic analysis found no benefit.

**`mobile-performance-and-release`** — `keyExtractor` is not optional, and
`getItemLayout` is the single highest-impact list option. Re-renders come from
inline objects, unmemoised providers, and parent list state. Touch targets differ
per platform, 48dp on Android and 44pt on iOS, and some accessibility actions work
on neither until tested on both.

**`email-deliverability`** — Three records, three jobs. **Exactly one SPF record
per domain**, and it must fit one DNS packet, which is why long `include:` chains
fail. DMARC passes when **either** SPF or DKIM passes *and is aligned*, so a
failing authentication is irrelevant if one is aligned. One-click unsubscribe
has five normative requirements, including a DKIM signature that must cover both
headers and an opaque URL.

### Performance and observability

**`performance-profiling`** — Profile before changing anything. In a flame graph,
width is time, the wide plateau at the top is the work, colour means nothing, and
**compare two profiles** rather than reading an absolute one. CPU profiling only
sees on-CPU time, so a program that is waiting looks fine. Connection pool
exhaustion fails as a **queue, not an error**.

**`concurrency-and-async`** — An `await` only yields if the awaited thing is
genuinely asynchronous, so a synchronous hash inside an async function blocks
every other request for its duration. `Promise.all` abandons the rest on first
failure and launches everything at once. **Never hold a lock across an `await`**,
and acquire multiple locks in a consistent global order, because that is the only
reliable deadlock prevention. Concurrency bugs need a loop or a race detector,
because a test that passes once has proved nothing.

**`observability-and-slos`** — Start from the error budget, not a metric, and
agree the consequence in advance or the number is a dashboard rather than a
control. **100% reliability is the wrong target**, because change is the top
cause of outages. Cardinality is the silent cost: every unique label value is a
separate time series.

### Reliability and lifecycle

**`release-engineering`** — Version numbers are a promise about **compatibility**,
not magnitude, and the judgement is about the consumer rather than the diff: a
changed default alters behaviour without anyone's code changing. The artifact is
immutable, so deploy the tag and pin by digest; rebuilding an old version is a new
build with a familiar name. The rollback decision has three cases, and the one
that catches people is a schema change, where rolling the code back does not
restore the data.

**`backup-and-disaster-recovery`** — A backup that has not been restored is a
hypothesis, and the restore is the deliverable rather than the job. **Replicas are
not backups**: a `DROP TABLE` propagates to every replica in seconds. RPO and RTO
must be defined first, because a nightly backup silently *is* a twenty-four-hour
RPO. Test against the largest dataset rather than the average, and give
immutable storage its own credentials so the attacker who reaches production
cannot delete the copies.

**`background-jobs-and-scheduling`** — A job that runs twice must be safe, because
retries, deploys during a run, and multi-instance deployments all produce that.
Cron has no knowledge of whether the last run finished, and every instance runs
it; `FOR UPDATE SKIP LOCKED` is the primitive that makes a claim correct. Locks
expire because workers die, so every claim needs a lease, and a heartbeat must be
written **during** the work or the job is indistinguishable from a hung one.

**`privacy-and-data-retention`** — Minimisation is the whole strategy, and it is
decided at design time. Deletion is a **distributed** problem: the record lives in
the database, in backups, in the warehouse, in logs, in search, and at third
parties, and a delete on one system is not compliance. Hashing an email does not
anonymise it, because the space is small and enumerable; use a keyed digest or a
surrogate, and test a re-identification attempt before calling it anonymised.

### Security

**`security-code-review`** — Work from the trust boundary inward, because a
review that scans for suspicious syntax misses the defect that does not look
suspicious. Separates authentication from authorisation and treats IDOR as the
common defect. Every finding must carry an exploit path, payload and concrete
fix.

**`prompt-injection-defense`** — The core control is **structural**, not
instructive: untrusted content must never occupy the position where instructions
live, so retrieved text stays in the user turn as data rather than being
concatenated into the system prompt. The cheapest defence is removing the
capability, and the shape to audit for is an agent that both **reads secrets** and
can make outbound requests. What does not work: telling the model to ignore
instructions in documents, because that instruction competes with a real one.

**`dependency-supply-chain-review`** — The point where most damage is preventable.
A typosquatting table, maintenance signals indicating transferred ownership, and
install scripts as the sharpest edge. Lockfile integrity as a security control,
and CI pinning with the first-time-contributor approval bypass called out.

**`http-security-headers`** — The actual header values, and four that are
routinely wrong. **`X-XSS-Protection` must be `0`**, because the legacy filter was
itself exploitable. HSTS is the one that can lock out every real user, so ramp it
rather than jumping to the preload value. Plus the nginx `always` trap that
leaves error pages unprotected.

### LLM and agent engineering

**`llm-application-development`** — Start from the evaluation, not the prompt, and
split the golden set so tuning and reporting use different data. **Retrieval is
where most RAG systems fail**, with a table separating "the document was
retrieved and ignored" from "it was never retrieved", because the fix is
opposite. Cost and latency are design constraints.

**`mcp-server-authoring`** — A tool description is a **prompt**, not
documentation, and it is the only part of the definition the model sees, so the
same workflow-summarisation trap applies as for skills. Two overlapping
descriptions are chosen between at random. Errors are results the model reads, so
return what to do differently rather than a stack trace. And the most important
control is capability: a tool that reads a page should not also be able to send
email, because an attacker needs the model to do something.

**`writing-agent-skills`** — The skill that governs this collection. Three
disclosure levels, the failure-first method, the description trap, and the
form-matching table. Ships two reference files covering description craft with
worked examples, and the evaluation protocol including near-miss negatives.

**`dispatching-parallel-agents`** — A three-row independence test covering files,
contracts and decisions, because most lost work is two agents writing one file
and the second write discarding the first. Requires explicit file ownership in
the prompt.

### Working within an agent's limits

These three describe the constraints an agent works inside rather than the work
it does. Most of what is written about agents assumes a larger context than
exists, and most of what goes wrong in long sessions is a violation of one of
these.

**`token-and-context-budget`** — The framing that matters: **the expensive
resource is attention, not tokens**, and relevance per token collapses long
before the token cap is reached. So the question is never "how do I fit this" but
"what is the smallest context that makes this decision correct". Its most concrete
rule is **read narrowly, cite exactly** — `path:line` instead of a reproduction,
which is cheaper, leaves room for reasoning, and is verifiable. On delegation: a
subagent's entire value is its summary, so the summary *shape* is what you are
paying for, and "look into the caching" is not a spec. And the number worth
watching is **context consumed per decision made**.

**`context-window-management`** — A window is not a bag, it is a spotlight. Three
consequences that contradict each other and are therefore worth stating
separately: **position matters** (the middle is attended to least), **retrieval
is lossy**, and **coherence degrades before the cap** — which is why "I have
plenty of context left" is not the same as "I can still do this correctly". The
design rule that follows is **compaction keeps conclusions and drops reasons**, so
a decision worth surviving must carry its `Why:` clause with it. Everything else
in the skill is about making the durable state live in a file, so losing the
window costs nothing.

**`hallucination-defense`** — Splits the thing people treat as one problem into
three with different defences: **hallucination** (invented fact), **confabulation**
(invented citation, API or path), and **drift** (answering a nearby question).
Drift is the one that gets missed, because the output is usually correct — just
about the wrong thing, and correctness does not make it an answer. The root cause
is that **uncertainty has no internal signal**, so "let me be more careful" cannot
work and only structure does: a claim is **either sourced or labelled, with no
third state**, and the label is never deleted to tidy the output. Includes the
highest-risk content list (versions, paths, identifiers, measurements) and the
rule that fixes it: *open the file, quote the lines you are changing, then edit*.

### Producing trustworthy output

The last mile. Where the previous three constrain what goes *into* an answer,
these three govern what actually reaches the reader.

**`evidence-first-writing`** — Written by the repository owner, and the sharpest
tool here for research output. Its rule is a three-way classification every
factual statement must fall into: **Read** (you opened a source and it says this),
**Stated** (someone else stated it, and you name who), or **Inferred** (and you
say so). A statement that is none of the three does not go in the answer. It also
covers links (only link what you opened, one primary source per claim, and a
wrong link is worse than no link), numbers (carried with the source's own
qualifiers, never silently rounded), and **confidence stated per item rather than
once for the answer**.

**`long-form-integrity`** — The failure nobody looks for, because the output is
long and looks like work. A model that runs out of useful output does not fail,
it **repeats itself** — the same phrase, word or line — until the budget ends, and
the reader concludes the whole system is broken. Covers the signature (`wwwwww`,
`000000`, tool names leaking into prose, a sentence that starts and never
finishes) and the check to run before delivering: scan the tail, because that is
where the loop begins.

**`arabic-news-briefing`** — The shape of a briefing read on a phone by someone
scanning forty headlines: not an essay, and each item standing alone and skimmable
in ten seconds. One template per item with **labelled fields** — what happened,
the details, the context, the analysis separated from the facts, and the source
URL — so the reader can stop reading at any field without losing the item.

**`honest-technical-reporting`** — The gap in a technical report is never
between right and wrong; it is between what happened and what the report says
happened, and that gap is usually one word. Its spine is a table of claim words
and their preconditions: writing **"fixed"** asserts the defect no longer occurs,
which means you reproduced it and watched it go; **"tests pass"** means you read
the summary and named the count. The rule is to report three separate things —
**done**, **verified**, **assumed** — because the common inflation is an
assumption written as a verification. The argument for it is asymmetric: one
honest "I do not know, here is how to check" costs a reader thirty seconds, and
one confident wrong answer costs them a decision they will not know to revisit.

### Checking your own work

These two came out of building this repository rather than from studying it, and
they are the least replaceable material in the collection, because everything
else in it can be found elsewhere.

**`trustworthy-checks`** — **A check that cannot fail is worse than no check**,
because it is believed. A checker that always passes and no checker produce the
same observable outcome, so the broken one is strictly more dangerous: it
converts "I did not look" into "I looked and there was nothing", silently and
indefinitely. The only test of a detector is a known-positive, so plant the defect
and assert it is found. **Pin both directions** — a detector that flags
everything and one that flags nothing fail in opposite ways and are equally
useless, and each mistake is invisible in the other's test. And "no findings" is
a claim about a population, not a result: report what you **scanned**, because
that is the only thing distinguishing a clean tree from an empty one.

**`shell-and-text-tooling`** — The measured traps of the tools repository
tooling is built from. `grep -q $'\r'` **never matches anything**, because grep
consumes the trailing CR as the pattern's own terminator; the fix is `-U`. The
opposite trap is worse: `grep -q $'\r\n'` **matches everything**, because a
newline in a pattern splits it and the empty remainder matches any file — it
reports the whole repository as defective, the obvious response is to normalise
all of it, and afterwards nothing looks wrong. Also covered: `\{0,\}` is not a
valid interval, `GROUPS` and `close` are names the shell already owns, and eight
subprocesses per file cost 265 s where two batched greps cost 1.3 s.

---

### Cross-cutting correctness

**`structured-logging-and-error-handling`** — The two domains where defects hide.
Log JSON with a stable machine-readable `event` field; **correlation IDs beat
timestamps**. Redact centrally in the serialiser so a new call site is safe by
default. Always pass the `cause`, and never let a stack trace reach the user.

**`date-time-handling`** — **There is no skill for this anywhere in the world**,
and it is one of the most bug-dense domains there is. Store UTC; the
language-level inconsistency where `new Date('2026-03-04')` parses as UTC midnight
but `new Date('2026-03-04T11:22')` parses as local. Adding 24 hours is not adding
a day, which is 23 or 25 across a DST transition.

---

## Design rules

- **Only six frontmatter keys are permitted**, and `name` must equal the
  directory. Extra keys hard-error on skill upload.
- **Descriptions are 80 to 110 characters.** This is a hard budget, not a style
  preference: at Codex's 8,000-character limit, a long description costs other
  skills their existence.
- **The description describes the trigger surface, never the workflow.**
- **Match the form to the failure.** See `writing-agent-skills`.
- **References stay one level deep**, because an agent reading a file that points
  at another may preview it and act on a partial read.
- **Nothing a validator could enforce is written down.**

Skills are named for situations, never for roles. There is no `helper`, `utils`
or `tools`, because a role does not tell an agent when to load anything.

---

## Repository layout

```text
.opencode/skills/          canonical skill source, 79 skills
skills/ .claude/ .agents/ .github/ .cursor/ .devin/ .cline/    generated mirrors
.cursor/rules/ .roo/rules/ .windsurf/rules/ .devin/rules/
.cline/rules/ .trae/rules/                            generated on-demand rules
.clinerules/ .continue/rules/ .goose/ .rules/ .amazonq/ .augment/
AGENTS.md  GEMINI.md  CLAUDE.md  CONVENTIONS.md  .cursorrules
.aider.conf.yml

dist/                       generated HTTP catalog with descriptions

VERSION  CHANGELOG.md       release version and English release notes
spec/upstream.sha256        fingerprint of the specification this collection targets
docs/i18n/                  translated entry points, one per language
docs/platforms.md            verified, structural, and not-yet-true support
docs/authoring.md           the contract every skill follows
docs/catalog.md             generated: all skills, routing sentences, provenance
agents.json                 machine-readable agent and protocol support matrix
skills.sh.json              registry groupings
opencode.jsonc              registers ./skills as a source for OpenCode
.claude-plugin/             Claude Code plugin marketplace

scripts/validate-skills.sh  spec conformance, catalog budget, doc drift
scripts/normalize.sh        strip UTF-8 BOM, force LF
scripts/set-descriptions.sh canonical routing sentences for every skill
scripts/sync-agents.sh      mirror the source to every skill discovery root
scripts/sync-rules.sh       generate flat rule files for non-spec agents
scripts/build-catalog.sh    build dist/index.json and the update manifest
scripts/build-catalog-doc.sh generate docs/catalog.md
scripts/check-upstream.sh   detect upstream specification drift
scripts/check-i18n.sh       verify translations are in step with the collection
scripts/release.sh          cut a release behind every gate
tests/run-tests.sh          23-case regression suite for the validator
install.sh                  install into any of 14 agents, local or global
```

---

## Tooling

```sh
scripts/normalize.sh            # strip BOM, force LF
scripts/normalize.sh --check    # report only, non-zero exit if anything needs fixing
scripts/set-descriptions.sh     # apply the canonical routing sentences
scripts/set-descriptions.sh --check
scripts/validate-skills.sh      # spec conformance, budgets, doc drift
scripts/validate-skills.sh --strict   # warnings also fail, as in CI
scripts/sync-agents.sh          # regenerate the skill mirrors
scripts/sync-agents.sh --check  # CI gate for drift, compares content not names
scripts/sync-rules.sh           # regenerate flat rule files
scripts/build-catalog.sh        # build dist/ for remote agents
scripts/build-catalog-doc.sh    # regenerate docs/catalog.md
scripts/check-upstream.sh       # detect drift in the Agent Skills specification
scripts/check-upstream.sh --accept
scripts/check-i18n.sh                # verify every translation lists the same domains
scripts/release.sh 1.2.0        # cut a release: run every gate, then tag
tests/run-tests.sh              # regression-test the validator itself
install.sh                      # install into any agent
install.sh --update             # pull the newest source and report what changed
```

The validator enforces the portable specification rather than any single agent's
lenient rules, so passing it means the collection loads in OpenCode, Claude Code
and every spec-compliant client alike. Beyond structural conformance it checks
the **catalog size budget** against both the Codex and Zed limits, the
**documentation catalog** for drift, and the two defects that break loading
quietly on POSIX hosts: a UTF-8 BOM and CRLF line endings.

It cannot tell you whether a skill is *good*. For that, `docs/authoring.md`
sets the bar: run an agent on a representative task without the skill, record
what it does wrong, and confirm the skill changes that behaviour.

---

## Contributing

Read `docs/authoring.md`, add the skill under `.opencode/skills/`, add its
description to `scripts/set-descriptions.sh`, assign it to a cluster in
`skills.sh.json`, then run the generators. CI runs normalisation, description
conformance, validation, both sync gates, the documentation gate, the regression
suite and a catalog build.

If the change ships, add a section for the new version to `CHANGELOG.md` and bump
`VERSION`. `scripts/release.sh` refuses to tag a version that has no notes,
because a release without release notes is an unannounced breaking change.

---

## License

MIT. See [LICENSE](LICENSE).