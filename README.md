# Essential Agent Skills

A curated, validated collection of **47 agent skills** covering the full arc of
software work: deciding what to build, building it test-first, getting it reviewed,
running it, operating it, and writing skills of its own.

Every skill is written to the open [Agent Skills
specification](https://agentskills.io/specification), enforced by a validator in
this repository, and mirrored into every agent discovery convention so it works
with any agent out of the box.

```sh
git clone <this-repo> && cd <this-repo> && ./install.sh
```

---

## Contents

- [Why this collection exists](#why-this-collection-exists)
- [Quick start](#quick-start)
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

Research into the existing ecosystem produced one finding that shaped
everything here.

**The saturated niche is the obvious one.** Of the 149 most-installed skills
ever published, about 44% are engineering-process meta-skills: planning, TDD,
debugging, code review. That niche is crowded and well served. Meanwhile
DevOps, backend design, infrastructure, authentication implementation, data
engineering and LLM engineering have either **no registry taxonomy at all** or
around thirty official vendor skills sitting at **zero installs**. Auth0 ships
fourteen authentication skills and not one of them has been installed. HashiCorp
ships eleven Terraform skills, all at zero. Stripe ships two, both at zero.

So the gap is not in "more process skills". It is in the domains with real
demand and no supply: containers, orchestration, pipelines, infrastructure as
code, incident response, API contracts, authentication, caching, message
queues, schema migrations, localisation, and date handling — the last of which
has **no skill anywhere in the world**.

Three published findings also shaped how each skill is written:

**The description is the whole game.** Only the name and description of a skill
are in context at every model step. A weak description makes a well-written skill
permanently unreachable, so each one names a situation, carries the literal error
text a user would report, and excludes its nearest neighbour.

**A description that summarises the workflow is actively harmful.** The
`superpowers` collection documented an agent following a plan taken from a
description and performing one code review where the body clearly specified two.
The body became documentation nobody read. Every description here describes the
*trigger surface* and never the procedure.

**Guidance should match the failure.** Prohibitions work when a rule is being
rationalised away under pressure. For output with the wrong shape, prohibitions
measurably produced *more* unwanted content than an equivalent positive recipe,
worse than giving no guidance at all. `writing-agent-skills` carries the full
table.

Finally, nothing mechanically checkable is written down. Where a rule could be a
lint, a CI gate or a validator, this repository enforces it instead, and
`docs/authoring.md` explains the reasoning.

---

## Quick start

Use the skills in this repository directly with any agent that reads the
`skills/` directory:

```sh
# OpenCode picks up ./skills and ./.opencode/skills via opencode.jsonc
opencode

# Claude Code picks up ./.claude/skills
claude

# Codex, Cline, Kilo, Amp, Zed, Goose, Gemini CLI, Augment, Roo, Cursor,
# Copilot, Junie, Devin and others read ./.agents/skills
```

Install them into your user-level directory so they apply to every project:

```sh
./install.sh                      # list all 14 supported agents and status
./install.sh opencode --global    # install for the current user
./install.sh agents --global      # serves ~24 agents at once
./install.sh claude --global

./install.sh --list               # every available skill id
./install.sh opencode --only sql-query-performance,systematic-debugging
./install.sh opencode --uninstall
```

Serve them to an agent that supports remote catalogs:

```sh
scripts/build-catalog.sh          # emits dist/index.json with descriptions
```

Install as a Claude Code plugin:

```text
/plugin marketplace add <owner>/<repo>
/plugin install essential-skills@essential-agent-skills
```

Or through the community registry:

```sh
npx skills add <owner>/<repo>          # project scope
npx skills add <owner>/<repo> -g       # global scope
```

Validate against the open specification with the reference CLI:

```sh
skills-ref validate .opencode/skills/systematic-debugging
```

---

## Supported agents and protocols

`agents.json` is the machine-readable version of this table and `install.sh` reads
it, so adding an agent means editing one file.

### Native skill discovery (progressive disclosure)

These read `SKILL.md` and only load a body when the description matches.

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
| Any catalog-capable agent | `dist/index.json` over HTTP | served URL |

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
| Twenty-five tools incl. Codex, Cursor, Copilot, Gemini, GitLab Duo, JetBrains | `AGENTS.md` | Pointer only |
| Aider | `.aider.conf.yml` with `read: [AGENTS.md]` | Opt-in, since Aider has no discovery |

On-demand agents get the full body with frontmatter, which reproduces
progressive disclosure. Agents that always load every rule get a single pointer
file instead, because 47 full bodies would overflow their context.

### Other protocols

- **MCP skills extension** (`io.modelcontextprotocol/skills`). `dist/index.json`
  carries a `description` per skill, which is what a host needs for level-one
  disclosure without fetching every file.
- **Plugin marketplace.** `.claude-plugin/marketplace.json`.
- **skills.sh registry.** `skills.sh.json` declares the groupings.
- **Reference validator.** `skills-ref validate`.

---

## How discovery works

An agent cannot use a skill it cannot find, and each convention expects
`SKILL.md` in a particular directory. There is exactly one source of truth, and
everything else is generated from it.

```
.opencode/skills/<skill-id>/SKILL.md      canonical, 47 skills
```

Generated by `scripts/sync-agents.sh`:

```
skills/<skill-id>/SKILL.md                spec layout, Claude Code plugin root, GitLab Duo
.claude/skills/…  .agents/skills/…  .github/skills/…
.cursor/skills/…  .devin/skills/…  .cline/skills/…
```

Generated by `scripts/sync-rules.sh`:

```
.cursor/rules/*.mdc                       full body, agentic
.roo/rules/*.md  .windsurf/rules/*.md  .devin/rules/*.md  .cline/rules/*.md  .trae/rules/*.md
.clinerules/agent-skills.md              index, for always-loaded rule engines
AGENTS.md  GEMINI.md  CONVENTIONS.md  CLAUDE.md  .cursorrules  AmazonQ.md  TABNINE.md
.aider.conf.yml
```

Generated by `scripts/build-catalog.sh`:

```
dist/index.json + dist/<skill-id>/…      HTTP catalog for remote agents
```

Everything is committed, so a fresh clone works with any agent without a build
step, and each generator has a `--check` mode that CI runs. Drift is impossible.

### The three levels of disclosure

1. **Metadata**, about 100 tokens. `name` and `description`, in context at every
   step for every installed skill. This is what makes a collection of 47
   affordable.
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
test that fails without the check" is verifiable; "add validation" is not. It
prefers decomposition at running seams and vertical slices over horizontal layers,
because a horizontal slice leaves nothing working until its final line.

**`writing-acceptance-criteria`** — Turns a vague request into statements two
people could disagree about, which is the actual test of completeness. Covers
the six cases that generate disagreement (empty, boundary, malformed, duplicate,
concurrent, partial failure), argues for explicit non-goals as the highest-value
line in the document, and insists on asking **one** question with a stated
default rather than five open ones.

**`test-driven-development`** — The red-green-refactor loop with the part most
write-ups omit: a test must fail **for the reason you expect**, or it has not
tested anything. Treats a test that is hard to write as a design signal, not a
testing inconvenience. For bugs, the failing test is the reproduction and is
non-negotiable.

**`systematic-debugging`** — Refuses any code change before there is a
hypothesis that can be disproved, because editing to "see what happens" destroys
the evidence while leaving the defect. Includes a table distinguishing
`ECONNREFUSED` from `ETIMEDOUT` from `ENOTFOUND`, because an error seen before
still fails for a new reason.

**`verification-before-completion`** — Evidence before assertion, with a mapping
from each claim to the command that would falsify it. Gives most attention to
**negative** claims, where nothing fails if you skip: "nothing else broke" is
checked by grepping for callers of a changed signature. Distinguishes exit code
zero from a genuinely passing run.

### Testing and review

**`requesting-code-review`** — Makes the review possible first: the requester
states the problem, the approach, the rejected alternative, and what is out of
scope. Quantifies reviewability — beyond roughly 800 changed lines reviewers
approve the shape rather than the logic.

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
highest-value artefact a contributor produces. Install from the lockfile
(`npm ci`, never `npm install`), check declared runtime versions before
dependencies, verify each service is actually healthy rather than merely started,
and **run the test suite before writing any code** so a broken environment is
distinguished from your own changes.

**`domain-modeling`** — Start from the vocabulary, not the schema. The schema
records storage; the domain model records meaning. A disagreement about a word is
a disagreement about the model, and it is far cheaper to find now than after three
teams implement incompatible meanings of "order status". Separate entity states
that are genuinely different, and push behaviour into the model so a rule is
written once.

**`improving-codebase-architecture`** — Demands evidence before proposing
structure. Looks for four specific findings (cyclic dependencies, shotgun
surgery, leaky abstractions, duplication with variation) rather than offering a
general critique, separates structural from style findings because bundling them
makes the structural ones harder to approve, and refuses the rewrite unless the
evidence is enumerable.

**`writing-technical-docs`** — Distinguishes the three genres, because mixing them
produces a document serving nobody. Its central principle is to document the
**decision**, not the code, with a worked example of why a batch cap is 500.
Prefers executable documentation, mapping things people write down to things that
should be generated or tested.

### Version control

**`using-git-worktrees`** — When a second working directory is genuinely right and
when it is overhead. Its most valuable section is the trap: a worktree has **no
dependencies of its own**, so it needs its own install, and two worktrees sharing
a build directory will corrupt each other's output.

**`finishing-a-development-branch`** — An ordered procedure, because skipping
ahead is how branches reach main with a failing test. Includes running the
install as well as the suite, and reading the diff as a reviewer rather than as
its author. Tabulates squash versus merge versus rebase, and states plainly that
force-pushing a shared branch is never acceptable.

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
empty, error, too much content, disabled, focus. Those are what get skipped, and
they are what separates finished from merely built.

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
role and key handling for free. Automated tools catch roughly a third; the rest
needs a manual pass.

**`localization-i18n`** — Never concatenate sentences, because word order differs
by language. Pluralisation belongs to the translation format, not to a ternary:
English has two forms and Arabic has six, so `n === 1` is wrong almost
everywhere. Includes the decimal-separator trap, where hard-coding `.` misprices
by a factor of a thousand in much of the world, and CSS logical properties for
right-to-left.

### APIs and integrations

**`rest-api-design`** — Error bodies are **RFC 9457 Problem Details**, not a
bespoke envelope, with four rules models break most: `status` is advisory and must
match the real HTTP status, `title` must not vary between occurrences, `detail`
is not machine-readable, and `type` must be an absolute URI because a relative
one resolves differently under different paths. Decides cursor versus offset
pagination before launch, because cursor cannot be retrofitted. Also covers
status code contracts and idempotency keys bound to a payload hash.

**`api-contract-versioning`** — Establishes whether you can break the API before
choosing a strategy, because guessing wrong is expensive in both directions. The
compatibility checklist catches the non-obvious cases: adding an enum value is
breaking, adding an optional request field is breaking for strict clients. Pairs
with tolerant readers and strict writers, and requires a machine-readable
deprecation signal rather than a date in prose.

**`graphql-api-security`** — N+1 as the default failure mode, invisible in
development at five posts and catastrophic at fifty thousand. Explains that
neither depth nor amount limiting is built in, and they are two different attacks:
a depth limit alone does not stop `posts(first: 99999999)`. The distinction that
matters most is that **persisted queries are a performance feature, not a
security control**, because APQ lets anyone register a new query.

**`webhook-integration`** — Verifying a signature is the whole job, and four
details are skipped somewhere: verify **raw bytes** before parsing, compare in
**constant time**, enforce a **timestamp tolerance** against replay, and
acknowledge `2xx` before doing the work. Distinguishes duplicate delivery from
malicious replay, and covers payments specifically, where a validly signed event
for the wrong amount is a real attack.

**`oauth-authentication`** — OAuth 2.1 is a draft, not an RFC, and states that
precisely. PKCE mechanics with the actual character ranges and hash construction.
The rule assistants get wrong: **a self-contained JWT cannot be revoked**, so
"stateless" is exactly what removes revocation, and first-party browser apps
should use server-side sessions. Refresh rotation with family-based replay
detection, and why `localStorage` for tokens is unrecoverable.

### Data and storage

**`sql-query-performance`** — Read the plan before changing anything, and what to
look for in it: rows estimated versus actual, a nested loop with a large outer
set, sort spill to disk, and the row-count explosion that is the real cause in
most bad plans. Sargable and non-sargable predicates side by side, the
leftmost-prefix rule for composite indexes with equality columns before range
columns, and why `COUNT(*)` and `EXISTS` beat their alternatives.

**`database-migrations`** — PostgreSQL's lock table, because `ALTER TABLE` takes
`ACCESS EXCLUSIVE` and that is why naive migrations take an application offline.
**Always set `lock_timeout`** so a migration fails fast instead of queueing behind
a long transaction. Expand and contract for anything breaking, with the reason
dropping a column in one deploy breaks rollback. Covers `CREATE INDEX
CONCURRENTLY`, `NOT VALID` plus `VALIDATE`, and batched keyset-cursor backfills.

**`caching-and-stampedes`** — Computes the herd so it is concrete: 2,000 requests
per second on a 400ms query is 800 concurrent identical queries, or 115,200 a day.
Four defences in order of effort, and the one people forget: **jitter is
mandatory**, because fixed TTLs synchronise every key created by the same deploy,
which a per-key lock cannot fix. Includes the `no-cache` versus `no-store`
distinction that causes real data leaks.

**`message-queue-processing`** — Exactly-once is a scoped claim usually oversold;
Kafka's own design documentation is quoted on the fine print and the three
possible commit orderings. Design for at-least-once plus idempotent consumers.
Ordering is per partition only, so key by entity id. Dead letter queue numbers
that are concrete (visibility timeout at least 6x the function timeout, and
`maxReceiveCount` at least 5), and the transactional outbox for the
database-plus-broker double write.

### Infrastructure and operations

**`docker-containerization`** — Layer order is cache order, and this is the
single highest-leverage Docker rule: copying the whole tree before installing
dependencies invalidates the install on every source change. Covers cache mounts
and the silent misconfiguration where they never reach CI. The **PID 1 problem**:
a process without an init gets no default signal handlers, so `docker stop` never
reaches it, which is why `CMD ["npm", "start"]` kills rather than shuts down.

**`kubernetes-deployment`** — Probes, where choosing wrong causes outages.
**Liveness must never check a dependency**, because a database hiccup then
restarts every pod at once and the storm lands on the database while it recovers.
The startup probe formula: defaults give a 30-second budget, so any slower app is
killed mid-boot. Also the request-versus-limit asymmetry, where a CPU limit is a
hard stall at the quota boundary rather than smooth throttling, and the
`maxUnavailable` percentage-rounding trap.

**`infrastructure-as-code`** — State is the hard part, not the syntax: state holds
secrets in plaintext, must be backed up before every operation, and one state per
environment. The plan is the review artefact, rendered from `show -json` so a
reviewer sees **replacements and destroys**, which are invisible in the code diff.
`prevent_destroy` for anything whose loss is unrecoverable, because deleting a
state-backed database does not empty it.

**`ci-pipeline-security`** — Pin actions to a SHA **and verify the SHA is real**,
because GitHub runs a matching commit regardless of which fork it came from.
Explains why `pull_request_target` checking out PR code is remote code execution
with production credentials, why `permissions: {}` should be the default, and why
caching must be disabled in release workflows.

**`incident-response`** — Mitigate first, diagnose second, because the fastest
correct action is almost always the one that undoes the most recent change. The
first fifteen minutes as a checklist, the separation of commander from operator,
updates on a timer even when there is no change, and the handoff document. The
postmortem is blameless for people and factual for systems, because a postmortem
that finds a person at fault has found nothing.

### Performance and observability

**`performance-profiling`** — Profile before changing anything. How to read a
flame graph: width is time, the wide plateau at the top is the work, colour means
nothing, and **compare two profiles** rather than reading an absolute one. CPU
profiling only sees on-CPU time, so a program that is waiting looks fine and the
problem remains. Connection pool exhaustion fails as a **queue, not an error**,
and the arithmetic that wakes people at 2am: replicas times pool size against
`max_connections`.

**`observability-and-slos`** — Start from the error budget, not a metric, and
agree the consequence in advance or the number is a dashboard rather than a
control. **100% reliability is the wrong target**, because change is the top
cause of outages. The four-week window and the worked arithmetic from the SRE
Workbook. Cardinality is the silent cost: every unique label value is a separate
time series, so a user ID in a label is unbounded by construction.

### Security

**`security-code-review`** — Work from the trust boundary inward, because a review
that scans for suspicious syntax misses the defect that does not look suspicious.
Maps entry points to sinks with a table of what each requires and how it fails.
Separates authentication from authorisation and treats IDOR as the common defect,
with the observation that scoping the query is stronger than checking afterwards.
Every finding must carry an exploit path, payload and concrete fix.

**`dependency-supply-chain-review`** — The point where most damage is preventable,
because adding is where the decision is still cheap. A typosquatting table,
maintenance signals indicating transferred ownership, and install scripts as the
sharpest edge, with a command to find every dependency that runs code at install
time. Lockfile integrity as a security control, and CI pinning with the
first-time-contributor approval bypass called out by name.

**`http-security-headers`** — The actual header values, and four that are
routinely wrong. **`X-XSS-Protection` must be `0`**, because the legacy filter was
itself exploitable. HSTS is the one that can lock out every real user, so ramp it
rather than jumping to the preload value. CSP nonces: never reuse, and never
combine with `unsafe-inline`, which silently disables the nonce. Plus the nginx
`always` trap that leaves error pages unprotected.

### LLM and agent engineering

**`llm-application-development`** — Start from the evaluation, not the prompt, and
split the golden set so tuning and reporting use different data. **Retrieval is
where most RAG systems fail**, with a two-row table separating "the document was
retrieved and ignored" from "the document was never retrieved", because the fix
is opposite. Chunk by structure, filter before retrieval rather than after, and
treat cost and latency as design constraints.

**`writing-agent-skills`** — The skill that governs this collection. Three
disclosure levels, the failure-first method, the description trap, and the
form-matching table: prohibitions for rules being rationalised away, positive
contracts for output with the wrong shape, required slots for elements being
omitted. Ships two reference files covering description craft with worked
examples, and the evaluation protocol including near-miss negatives.

**`dispatching-parallel-agents`** — A three-row independence test covering files,
contracts and decisions, because most lost work is two agents writing one file
and the second write discarding the first. Requires explicit file ownership in
the prompt, keeps genuinely serial work serial, and requires verifying each
agent's claims rather than accepting its report.

### Cross-cutting correctness

**`structured-logging-and-error-handling`** — The two domains where defects hide.
Log JSON with a stable machine-readable `event` field; **correlation IDs beat
timestamps**. Levels have specific meanings, and logging a client validation
failure at `error` trains everyone to ignore the error level. Redact centrally in
the serialiser so a new call site is safe by default. Always pass the `cause`,
and never let a stack trace reach the user.

**`date-time-handling`** — **There is no skill for this anywhere in the world**, and
it is one of the most bug-dense domains there is. Store UTC; the language-level
inconsistency where `new Date('2026-03-04')` parses as UTC midnight but
`new Date('2026-03-04T11:22')` parses as local. Adding 24 hours is not adding a
day, which is 23 or 25 across a DST transition. Midnight is not a day boundary,
which is why the off-by-one-day bug appears on roughly two days a year and
survives testing. Includes the boundary test cases that find real bugs.

---

## Design rules

Every skill follows the contract in `docs/authoring.md`:

- **Only six frontmatter keys are permitted**, and `name` must equal the
  directory. Extra keys hard-error on skill upload, so Claude Code-only fields
  are not used.
- **The description describes the trigger surface, never the workflow.** It
  includes literal error strings the agent will see, and an anti-trigger where a
  neighbouring skill exists.
- **Match the form to the failure.** See `writing-agent-skills`.
- **References stay one level deep**, because an agent reading a file that points
  at another may preview it and act on a partial read.
- **Say whether to run a script or read it.**
- **Nothing a validator could enforce is written down.**

Skills are named for situations, never for roles. There is no `helper`, `utils`
or `tools`, because a role does not tell an agent when to load anything.

---

## Repository layout

```text
.opencode/skills/          canonical skill source, 47 skills
skills/                     generated: spec layout, plugin root, GitLab Duo
.claude/ .agents/ .github/ .cursor/ .devin/ .cline/   generated: skill mirrors
.cursor/rules/ .roo/rules/ .windsurf/rules/ .devin/rules/
.cline/rules/ .trae/rules/                            generated: on-demand rules
.clinerules/ .continue/rules/ .goose/ .rules/ .amazonq/ .augment/
AGENTS.md  GEMINI.md  CLAUDE.md  CONVENTIONS.md  .cursorrules
.aider.conf.yml

dist/                       generated: HTTP catalog with descriptions

docs/authoring.md           the contract every skill follows
docs/catalog.md             generated: all skills, routing sentences, provenance
agents.json                 machine-readable agent and protocol support matrix
skills.sh.json              registry groupings
opencode.jsonc              registers ./skills as a source for OpenCode
.claude-plugin/             Claude Code plugin marketplace

scripts/validate-skills.sh  spec conformance validator
scripts/normalize.sh        strip UTF-8 BOM, force LF
scripts/sync-agents.sh      mirror the source to every skill discovery root
scripts/sync-rules.sh       generate flat rule files for non-spec agents
scripts/build-catalog.sh    build dist/index.json for remote agents
scripts/build-catalog-doc.sh generate docs/catalog.md from the skills
tests/run-tests.sh          17-case regression suite for the validator
install.sh                  install into any of 14 agents, local or global
```

---

## Tooling

```sh
scripts/normalize.sh            # strip BOM, force LF
scripts/normalize.sh --check    # report only, non-zero exit if anything needs fixing
scripts/validate-skills.sh      # spec conformance
scripts/validate-skills.sh --strict   # warnings also fail, as in CI
scripts/sync-agents.sh          # regenerate the skill mirrors
scripts/sync-agents.sh --check  # CI gate for drift
scripts/sync-rules.sh           # regenerate flat rule files
scripts/sync-rules.sh --check   # CI gate for drift
scripts/build-catalog.sh        # build dist/ for remote agents
scripts/build-catalog-doc.sh    # regenerate docs/catalog.md
scripts/build-catalog-doc.sh --check
tests/run-tests.sh              # regression-test the validator itself
install.sh                      # install into any agent
```

The validator enforces the portable specification rather than any single agent's
lenient rules, so passing it means the collection loads in OpenCode, Claude Code
and every spec-compliant client alike. It checks ids, frontmatter delimiters,
allowed keys, `name` matching its directory, length limits, flat metadata, body
size, reference existence and depth, duplicate names, catalog consistency,
documentation drift, and the two defects that break loading quietly on POSIX
hosts: a UTF-8 BOM and CRLF line endings.

It cannot tell you whether a skill is *good*. For that, `docs/authoring.md`
sets the bar: run an agent on a representative task without the skill, record
what it does wrong, and confirm the skill changes that behaviour.

---

## Contributing

Read `docs/authoring.md`, add the skill under `.opencode/skills/`, assign it to a
cluster in `skills.sh.json`, then run the generators. CI runs normalisation,
validation, both sync gates, the documentation gate, the regression suite and a
catalog build. Details in `CONTRIBUTING.md`.

---

## License

MIT. See [LICENSE](LICENSE).