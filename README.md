# Essential Agent Skills

A curated, validated collection of **23 agent skills** that covers the work an AI
coding agent actually does: planning, testing, debugging, review, version
control, architecture, documentation, interface work, accessibility, security,
supply chain, and writing skills.

Every skill is written to the open [Agent Skills
specification](https://agentskills.io/specification), enforced by a validator in
this repository, and mirrored into every agent discovery convention so it works
out of the box.

```sh
git clone <this-repo> && cd <this-repo> && ./install.sh
```

---

## Contents

- [Why this exists](#why-this-exists)
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

## Why this exists

Most public skill collections are unvalidated. They accumulate skills written in
the same shape, with descriptions that summarise their own workflow, and nothing
checks whether a referenced file exists or whether two skills fight over the same
situation.

Three findings shaped this collection, all from published sources rather than
opinion:

**The description is the whole game.** Only the name and description of each
skill are in context at every model step. The body is never read unless the agent
decides to load it. A weak description makes a well-written skill permanently
unreachable.

**A description that summarises the workflow is actively harmful.** The
`superpowers` collection documented an agent following a plan taken from the
description and performing one code review where the body clearly specified two.
The body became documentation nobody read. This collection therefore describes
the *trigger surface* and never the procedure. Anthropic's own guidance pushes
the other way, asking for "what and when"; the synthesis used here keeps their
anti-trigger clauses and literal error strings, and drops their workflow
summaries. The reasoning is written up in `docs/authoring.md`.

**Guidance should match the failure.** Prohibitions work when a rule is being
rationalised away under pressure. For output that has the wrong shape, a
prohibition measurably produced *more* unwanted content than an equivalent
positive recipe, worse than giving no guidance at all. Each skill here picks its
form from the failure it targets, and the table for doing so is in
`docs/authoring.md`.

Everything here is validated by `scripts/validate-skills.sh`, which has its own
16-case regression suite.

---

## Quick start

Use the skills in this repository directly with any agent that reads the
`skills/` directory:

```sh
# OpenCode picks up ./skills and ./.opencode/skills automatically via opencode.jsonc
opencode

# Claude Code picks up ./.claude/skills automatically
claude

# Anything following the open spec finds ./.agents/skills
# VS Code / Copilot also finds ./.github/skills
```

Install them into your user-level directory so they apply to every project:

```sh
./install.sh                      # show every agent and what is installed
./install.sh opencode --global    # install for the current user
./install.sh claude --global
./install.sh agents --global
./install.sh github --global

./install.sh --list               # every available skill id
./install.sh opencode --only sql-query-performance,systematic-debugging
./install.sh opencode --uninstall
```

Serve them to an agent that supports remote catalogs:

```sh
scripts/build-catalog.sh          # emits dist/index.json
# then serve dist/ from any static host and point the agent at that URL
```

Install as a Claude Code plugin:

```text
/plugin marketplace add <owner>/<repo>
/plugin install essential-skills@essential-agent-skills
```

Validate a skill against the open specification with the reference CLI:

```sh
skills-ref validate .opencode/skills/systematic-debugging
```

---

## Supported agents and protocols

`agents.json` is the machine-readable version of this table; `install.sh` reads
it, so adding an agent means editing one file.

| Agent | Protocol | Project path | User path |
| --- | --- | --- | --- |
| OpenCode | filesystem | `.opencode/skills`, `skills` | `~/.config/opencode/skills` |
| Claude Code | filesystem, plugin | `.claude/skills` | `~/.claude/skills` |
| Agent Skills spec clients (VS Code Copilot, Codex, others) | filesystem | `.agents/skills` | `~/.agents/skills` |
| GitHub Copilot | filesystem | `.github/skills` | `~/.github/skills` |
| Any catalog-capable agent | HTTP | `dist/index.json` | served URL |

The format is the open specification, so any client implementing it works
without further change. Portability is why this repository validates against the
stricter portable spec rather than against one agent's looser rules.

---

## How discovery works

An agent cannot use a skill it cannot find. Each convention expects
`<skill-id>/SKILL.md` in a particular directory, so the same collection is
mirrored into all of them.

There is exactly one source of truth:

```
.opencode/skills/<skill-id>/SKILL.md     canonical
```

and four generated mirrors, produced by `scripts/sync-agents.sh`:

```
skills/<skill-id>/SKILL.md               spec layout, and the Claude Code plugin root
.claude/skills/<skill-id>/SKILL.md
.agents/skills/<skill-id>/SKILL.md
.github/skills/<skill-id>/SKILL.md
```

The mirrors are committed so a fresh clone works with any agent without a build
step, and `scripts/sync-agents.sh --check` runs in CI, so drift is impossible.
Edit the canonical copy only.

### The three levels

An agent reads a skill in three stages, and the whole design follows from keeping
each stage small:

1. **Metadata**, about 100 tokens. `name` and `description`, in context at every
   step for every installed skill. This is what makes a large collection
   affordable.
2. **Instructions**, under 5k tokens. The `SKILL.md` body, read once when the
   skill triggers, and it then stays in the conversation.
3. **Resources**, unbounded. `references/`, `scripts/`, `assets/`, loaded on
   demand and costing nothing until touched.

`writing-agent-skills` applies this to itself: its long-form material sits in
`references/` while the body stays a tight operating procedure.

---

## The collection

### Craft and process

#### `planning-before-implementation`
Decides whether a change is worth planning, and makes the plan checkable. Its
central rule is that a plan is a list of **states**, not activities: "add
validation" is an activity, "reject requests missing `owner_id` with 400 before
any query runs, covered by a test that fails without the check" is verifiable.
It teaches decomposition at running seams and prefers vertical slices over
horizontal layers, because a horizontal slice leaves nothing working until the
final line. It also covers correcting a plan mid-flight, which is cheap, and
correcting it *silently*, which is not.

#### `writing-acceptance-criteria`
Turns a vague request into statements two people could disagree about, which is
the actual test of whether criteria are done. It gives the shape to cover (happy
path, empty, boundary, malformed, duplicate and concurrent, partial failure),
argues for writing explicit non-goals as the highest-value line in the document,
and insists on asking **one** question with a stated default rather than five
open ones. The recurring failure it names is writing criteria after the first
line of implementation, at which point they describe what happened rather than
decide what should.

#### `test-driven-development`
The red-green-refactor loop with the part most write-ups omit: a test must fail
**for the reason you expect**, or it has not tested anything. It treats a
test that is hard to write as a design signal rather than a testing
inconvenience, with concrete examples of what each kind of difficulty means. It
covers bug fixes, where the failing test is the reproduction and is
non-negotiable, and legacy code with no tests, where the answer is a
characterisation test recording what the code currently does rather than what it
should.

#### `systematic-debugging`
Refuses any code change before there is a hypothesis that can be disproved,
because editing to "see what happens" destroys the evidence while leaving the
defect. It proceeds by reproduction, reading the actual failure, bisecting the
hypothesis space, stating one falsifiable hypothesis at a time, and fixing the
cause rather than the symptom. It includes a table distinguishing `ECONNREFUSED`
from `ETIMEDOUT` from `ENOTFOUND`, because an error seen before still fails for
a new reason, and explicit stop rules for when to stop investigating and ask.

#### `verification-before-completion`
Evidence before assertion. The claim being made determines the command that
would falsify it, and the skill gives that mapping as a table. It gives most
attention to verifying **negative** claims, where nothing fails if you skip:
"nothing else broke" is checked by grepping for the callers of a changed
signature. It also distinguishes exit code zero from a genuinely passing run,
since suites that report skips and summarisers that downgrade failures both
exit zero.

### Review and quality

#### `requesting-code-review`
Starts with making the review possible: the requester states the problem, the
approach and the rejected alternative, and what is out of scope. It has the
requester review their own diff for four specific things, including the fact that
a drive-by reformat costs reviewer attention and buys nothing. It quantifies
reviewability, since beyond roughly 800 changed lines reviewers approve the
shape rather than the logic, and it covers disagreeing with a reviewer without
either conceding a valid point or defending an indefensible one.

#### `receiving-code-review`
Sorts every comment into correctness, contract, maintainability, and preference
**before** acting on any of them, because acting in arrival order gives a naming
preference the same attention as a data-loss defect. Its main rule is that a
comment is a claim about code, and the reviewer may be right about the code and
wrong about the context, so verify first. It handles conflicting reviewers by
surfacing a specific answerable question rather than picking one, and it requires
every comment to end in exactly one of three states, since "unaddressed" reads
identically to "missed".

#### `property-based-testing`
For the case where example tests are structurally insufficient because the input
space is too large to enumerate. It frames properties as invariants over the input
space, warns that the most common mistake is testing against random strings when
the function needs structured input, and explains that the generated counterexample
is the actual deliverable. Shrinking is presented as the reason the technique is
worth adopting, with the specific advice not to reject small inputs inside the
property, which silently disables it. It also states what property testing does
**not** prove.

#### `webapp-testing`
Driving a real browser without the flakiness that usually comes with it. The
core rule is to wait for conditions and never for time, with the reason given: a
sleep passes when the machine is idle and reports load rather than the bug
otherwise. It requires locating elements by role and accessible name, which
tests accessibility as a side effect, and treating console errors and 4xx/5xx
responses as first-class signal, since a test can pass while the page is full of
errors. It keeps end-to-end tests few and shallow and gives an ordered checklist
for the UI bug that will not reproduce.

#### `refactoring-without-breaking-behaviour`
Behaviour must be pinned by a test before structure changes, and where it cannot
be, the refactor is too broad. It requires small reversible steps, one rename or
extract per commit, each independently revertible. Its most distinctive advice is
to delete more often than extract, with guidance on telling genuine duplication
from three near-identical blocks that differ in strategy. It also covers the case
where the test suite is the obstacle, with a symptom table for telling that apart
from a refactor that actually changed behaviour.

### Version control, architecture, and documentation

#### `using-git-worktrees`
When a second working directory is genuinely the right tool and when it is
overhead for a single task. Its most valuable section is the trap: a worktree has
no dependencies of its own, so it needs its own install, and two worktrees
sharing a `target/` or `.next/` directory will corrupt each other's build output.
It also presents the least obvious use, comparing two revisions side by side to
run both suites at once instead of stashing repeatedly.

#### `finishing-a-development-branch`
An ordered procedure, because skipping ahead is how branches reach main with a
failing test. It includes running the install as well as the suite, since a
passing suite on stale dependencies is a common false positive, and reading the
diff as a reviewer rather than as its author. It tabulates squash versus merge
versus rebase with the cost of each, states plainly that force-pushing a shared
branch is never acceptable, and distinguishes `--force` from `--force-with-lease`.

#### `resolving-merge-conflicts`
Starting from what a conflict actually is: git saying it cannot decide whether two
changes are compatible. It establishes the three-way view, because knowing that
`HEAD` is yours and theirs is the other side is the single most commonly
reversed fact, and shows `--conflict=diff3` for revealing the base version.
It tabulates the files that must never be hand-resolved, such as lockfiles and
generated clients, with the correct procedure instead. It also covers the
inverted semantics of a rebase conflict, where `HEAD` is no longer your branch.

#### `improving-codebase-architecture`
Demanding evidence before proposing structure, and giving the commands that
produce it: churn analysis and co-change frequency, which reveal the real module
boundaries. It looks for four specific findings rather than offering a general
critique, separates structural problems from style findings because bundling them
makes the structural ones harder to approve, and ranks work by risk against
payoff so the churniest and most expensive files come first. It refuses the
rewrite unless the evidence is enumerable, and explains why incremental
replacement is the same work without a period where neither system works.

#### `writing-technical-docs`
Distinguishing the three genres, because mixing them produces a document serving
nobody: a tutorial teaches by doing, a how-to serves one task, a reference is
exhaustive and non-narrative. Its central principle is to document the decision
rather than the code, with a worked example of why a batch cap is 500. It
prefers executable documentation, with a table mapping things people write down to
things that should be generated or tested, and it names the patterns that make
documentation rot, including time-sensitive claims and screenshots.

### Interface and security

#### `frontend-design`
Establishing scale before decoration, since most unconvincing interface work has
arbitrary spacing and type rather than a colour problem. It gives a modular type
scale, a 4px spacing grid, and the relational rule that the gap between
components is one or two steps larger than the gap inside them. Colour is
presented as semantic roles rather than values, so dark themes are a second value
set. The section that matters most in practice is the states: loading, empty,
error, too much content, disabled, focus. Those are what get skipped, and they
are what makes a component finished rather than merely built.

#### `web-design-guidelines`
A review method that separates the measurable from the judgement, because mixing
`contrast is 3.1:1` with `the layout feels cramped` gets everything dismissed as
opinion. Objective findings carry thresholds: 44 by 44 CSS pixel targets, 4.5:1
and 3:1 contrast ratios, reflow at 400% zoom or 320px, and the `user-scalable=no`
viewport meta tag that breaks it outright. It then ranks the ten most common
defects found in real review, led by the clickable `div` and the modal that does
not trap focus, and requires severity to be reported honestly so blockers are
not buried among style notes.

#### `accessibility-audit`
A six-pass audit in dependency order, where a contrast audit of a control that
cannot be reached by keyboard is wasted effort: keyboard, semantics, names and
roles, contrast, dynamic behaviour, then motion and timing. The strongest
material is semantic: the cheapest accessibility work is deleting the wrong
element, and the correct version of a clickable `div` gets focusability, role and
key handling for free. It gives ordered preference for accessible names, covers
live regions and focus trapping in dialogs, and is explicit that automated tools
are a floor, catching roughly a third of issues, with the remainder needing a
manual pass.

#### `security-code-review`
Working from the trust boundary inward, because a review that scans for
suspicious syntax misses the defect that does not look suspicious. It maps entry
points to sinks, with a table of what each sink actually requires and how it
fails: shell `exec`, SQL concatenation, path traversal, unescaped templates, open
redirects. It separates authentication from authorisation and treats IDOR as the
common authorisation defect, with the observation that scoping the query is
stronger than checking afterwards. Every finding must carry an exploit path,
payload, and concrete fix, because "this could be vulnerable if the input is not
validated" is noise.

#### `dependency-supply-chain-review`
The point at which most damage is preventable, because adding is where the
decision is still cheap. It gives the commands to run before installing
anything, a typosquatting table to check the package name against what the
documentation told you, and the maintenance signals that indicate ownership has
transferred. Install scripts are treated as the sharpest edge, with a command to
find every dependency that runs code at install time and criteria for
distinguishing a legitimate native build from a malicious one. It covers auditing
an existing tree, lockfile integrity as a security control, and the CI pipeline
risks, including pinned action SHAs and the `pull_request_target` mistake.

### Agent operation

#### `writing-agent-skills`
The skill that governs the rest of this collection, so it carries the
evidence-based findings rather than generic advice. It teaches the three
disclosure levels, the failure-first method of writing a skill, and the
description trap. Its most distinctive contribution is the form-matching table:
prohibitions for rules being rationalised away, positive contracts for output
with the wrong shape, required slots in templates for elements being omitted, and
conditionals keyed to observable predicates for conditional behaviour. It
references `references/description-craft.md` for the full description treatment
with before-and-after examples, and `references/eval-protocol.md` for how to
evaluate a skill, including building a trigger set with near-miss negatives.

#### `dispatching-parallel-agents`
A three-row independence test covering files, contracts, and decisions, because
most lost work in parallel dispatch is two agents writing one file and the second
write discarding the first. It requires explicit file ownership in the prompt,
lists the five things a subagent needs because it starts with none of your
context, and keeps genuinely serial work serial, since decisions every
subsequent task depends on must be made once and broadcast. It also argues
against fan-out when integration costs as much as the work, and requires
verifying each agent's claims rather than accepting its report.

#### `sql-query-performance`
Reading the plan before changing anything, with a list of what to look for: rows
estimated versus actual, the nested loop with a large outer set, sort spill to
disk, and the row-count explosion that is the real cause in most bad plans. It
gives sargable and non-sargable predicates side by side so the difference is
concrete rather than conceptual, covers the leftmost-prefix rule for composite
indexes with the guidance to put equality columns before range columns, and
treats the N+1 query as the most common application-side defect. It also covers
what property testing would not find here: `COUNT` versus `EXISTS`, and the
warning that caching is not a query optimisation.

---

## Design rules

Every skill in this collection follows the same contract, written up in full in
`docs/authoring.md`:

- **Only six frontmatter keys are permitted**, and `name` must equal the
  directory. Extra keys hard-error on skill upload, so Claude Code-only fields
  are not used.
- **The description describes the trigger surface, never the workflow.** It
  includes literal error strings the agent will actually see, and an anti-trigger
  where a neighbouring skill exists.
- **Match the form to the failure.** See the table under
  `writing-agent-skills`.
- **References stay one level deep**, because an agent reading a file that points
  at another may preview it and act on a partial read.
- **Say whether to run a script or read it.** Ambiguity causes the agent to read
  code it should have executed.
- **Nothing that a validator could enforce is written down.** If a rule is
  mechanically checkable, this repository checks it in CI instead.

Skills here are also deliberately named for situations rather than roles. There
is no `helper`, `utils`, or `tools`, because a role does not tell an agent when
to load anything.

---

## Repository layout

```text
.opencode/skills/          canonical skill source
skills/                     generated mirror, and the Claude Code plugin root
.claude/skills/             generated mirror
.agents/skills/             generated mirror
.github/skills/             generated mirror
dist/                       generated HTTP catalog

docs/authoring.md           the contract every skill follows
docs/catalog.md             the collection with routing sentences and provenance
agents.json                 machine-readable agent and protocol support matrix
opencode.jsonc              registers ./skills as a source for OpenCode
.claude-plugin/             Claude Code plugin marketplace

scripts/validate-skills.sh  spec conformance validator
scripts/normalize.sh        strip UTF-8 BOM, force LF line endings
scripts/sync-agents.sh      propagate the canonical source to every mirror
scripts/build-catalog.sh    build dist/index.json for remote agents
tests/run-tests.sh          16-case regression suite for the validator
install.sh                  install into any agent, project or global
```

---

## Tooling

```sh
scripts/normalize.sh            # strip BOM, force LF
scripts/normalize.sh --check    # report only, non-zero exit if anything needs fixing
scripts/validate-skills.sh      # spec conformance
scripts/validate-skills.sh --strict   # warnings also fail, as in CI
scripts/sync-agents.sh          # regenerate the four mirrors
scripts/sync-agents.sh --check  # CI gate for drift
scripts/build-catalog.sh        # build dist/ for remote agents
tests/run-tests.sh              # regression-test the validator itself
```

The validator enforces the portable specification rather than any single agent's
lenient rules, so passing it means the collection loads in OpenCode, Claude Code,
and spec-compliant clients alike. It checks ids, frontmatter delimiters, allowed
keys, `name` matching its directory, length limits, flat metadata, body size,
reference existence and depth, duplicate names, and the two defects that break
loading quietly on POSIX hosts: a UTF-8 BOM and CRLF line endings.

It cannot tell you whether a skill is *good*. For that,
`docs/authoring.md` sets the bar: run an agent on a representative task without
the skill, record what it does wrong, and confirm the skill changes that
behaviour.

---

## Contributing

Read `docs/authoring.md`, add the skill under `.opencode/skills/`, add a row to
`docs/catalog.md`, run the tooling, and let `scripts/sync-agents.sh` propagate
it. CI runs normalisation, validation, mirror sync, the regression suite, and a
catalog build. Details in `CONTRIBUTING.md`.

---

## License

MIT. See [LICENSE](LICENSE).