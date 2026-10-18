# Changelog

All notable changes to this collection are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

A version covers the **collection**, not the tooling separately: adding a skill,
changing a routing sentence, and changing the validator are all the same kind of
event to a consumer, because all three change which skills reach them.

---

## [1.1.0] - 2026-10-18

Expanded the collection from 47 to 67 skills, closing the remaining gaps in a
complete engineering practice. Two of the new skills cover areas that had no
guidance anywhere in the ecosystem. This is also the first release with a
versioned, automated update path.

### Added

**Agent and protocol surface**

- `mcp-server-authoring` — building MCP servers and tools. This was the largest
  internal gap: the collection distributed over MCP but carried no guidance for
  producing a server. Carries the rule that a tool description is a prompt rather
  than documentation, so the workflow-summarisation trap that applies to skills
  applies here too.

**Security**

- `prompt-injection-defense` — indirect injection through retrieved content and
  tool output. The central control is structural: untrusted text never occupies
  the position where instructions live.

**Runtime**

- `concurrency-and-async` — races, deadlocks, event-loop blocking, cancellation,
  and bounded concurrency. Covers the distinction between awaiting an actually
  asynchronous operation and awaiting a synchronous one.

**Reliability and lifecycle**

- `release-engineering` — version semantics, changelog discipline, immutable
  artifacts, and the three distinct rollback cases.
- `backup-and-disaster-recovery` — recovery objectives, restore testing, and the
  distinction between replicas and backups.
- `background-jobs-and-scheduling` — job claiming, leases, retry budgets, and
  heartbeat semantics.
- `privacy-and-data-retention` — data minimisation, retention by construction, and
  deletion as a distributed problem.

**Version control**

- `git-internals` — reflog recovery, automated bisection, hooks, and submodule
  pointers.

**Producing trustworthy output**

Added by the repository owner, written directly on GitHub and merged in.

- `evidence-first-writing` — every factual statement must be Read, Stated or
  Inferred, and a statement that is none of the three does not go in the answer.
  Covers links, numbers, and confidence stated per item rather than once per
  answer. See `hallucination-defense` for the complementary half: this governs
  delivery, that one governs prevention.
- `long-form-integrity` — a model that runs out of useful output does not fail,
  it repeats itself. Covers the signature and the pre-delivery check, because the
  failure is invisible in long output that looks like work.
- `arabic-news-briefing` — the item shape for a briefing scanned on a phone:
  labelled fields, the analysis separated from the facts, and a real source URL.

**Checking your own work**

- `trustworthy-checks` — writing validators, gates and CI checks that can
  actually fail. Written after this repository shipped a check which reported
  "already normalized" for its entire life while being structurally unable to
  detect anything. Covers the asymmetry that makes a silently broken gate worse
  than no gate, planting a known-positive as the only real test of a detector,
  pinning both failure directions, and reporting the scanned population rather
  than only the findings.
- `shell-and-text-tooling` — the measured behaviour of the primitives repository
  tooling is built from. `grep -q $'\r'` matches nothing and `grep -q $'\r\n'`
  matches everything, both for reasons that are not obvious and neither of which
  reports an error. Also: invalid sed intervals, names the shell already owns,
  the impossibility of holding a NUL in a bash string, quoting that degrades at
  each wrapper layer, and the measured difference between per-file subprocesses
  and batched ones.

**Working within an agent's limits**

- `token-and-context-budget` — spending a context window well. The framing is
  that the binding resource is attention rather than tokens, so relevance per
  token is what decays. Read narrowly and cite exactly, delegate only when the
  work will not fit, and specify a subagent's return shape because its summary is
  the entire value delivered.
- `context-window-management` — surviving a window rather than spending one.
  Position matters more than volume, retrieval is lossy, and coherence degrades
  before the token cap, so length is not capacity. Compaction preserves
  conclusions and drops reasons, which is why a decision worth surviving carries
  its `Why:` clause, and why the durable state belongs in a file.
- `hallucination-defense` — separating hallucination, confabulation and drift,
  which share a name and need different defences. Drift is the one that survives
  unnoticed because the answer is correct about a nearby question. The root
  cause is that uncertainty produces no internal signal, so the defences are
  structural: a claim is sourced or labelled, never silently neither.

**Working in a codebase**

- `codebase-decomposition` — file length is a symptom and unrelated reasons to
  change is the disease, with a command to count them. Split by change axis
  rather than by noun, prefer a narrow surface over a re-exporting barrel, and
  treat `utils` as a question rather than a destination.
- `up-to-date-tooling` — checking a version instead of recalling one, with a
  fixed resolution order from the lockfile down to your own prior. Includes the
  rule against widening a lockfile inside a bugfix, because that makes the diff
  unreviewable, and the dividing line: if a wrong answer would compile or run,
  check it.

**Release and update mechanism**

- `VERSION` and this changelog, with semantic versions covering the collection
  rather than the tooling. A new skill, a reworded routing sentence and a changed
  validator are the same kind of event to a consumer, because all three change
  which skills reach them.
- `scripts/release.sh` — cuts a release behind every gate, and refuses to tag a
  version that has no section in this file.
- `install.sh --update` — pulls the newest source and reports the version
  transition, any change in skill count, and the new release notes.
- `install.sh --version`.
- `.github/workflows/release.yml` — publishes on a tag, attaching the source
  tarball, its SHA-256 sums, the catalog and the update manifest. It re-checks
  that the tag matches `VERSION` and is reachable from `main`, because those are
  the two mistakes that actually happen.
- `.github/workflows/daily.yml` — re-verifies the collection daily, keeps a
  rolling `latest` release for anything that would rather poll than pull, and
  fingerprints the upstream specification to notice when it changes underneath
  the collection.
- `scripts/check-upstream.sh` — compares the specification fingerprint, records a
  new one only on request, and explains why accepting one too early silences the
  signal permanently.
- `spec/upstream.sha256` — the fingerprint this collection currently targets.
- `dist/update-manifest.json` — a small, stable manifest carrying the collection
  version, the catalog cache key, a content digest and a build timestamp, so a
  poller can detect a change without parsing the catalog.
- `scripts/check-repo-state.sh` — the marketplace manifest and the executable bit
  on tracked scripts, with every path overridable so a test can point it at a
  fixture. Answers in under a second.

### Changed

- `improving-codebase-architecture`, `css-architecture`, `accessibility-audit`,
  `database-migrations`, `dispatching-parallel-agents`, `environment-bootstrap`,
  `domain-modeling` and `verification-before-completion` received shorter routing
  sentences, adding about ninety characters of headroom to the catalog budget.
- `docs/catalog.md` and `AGENTS.md` remain generated, so the skill count in them
  cannot drift from the skill tree.
- `dist/index.json` now carries `collectionVersion` alongside the per-skill
  catalog cache key. Conflating the two is a real bug: using the semver alone as
  the cache key serves a stale catalog after every skill edit that did not come
  with a release, which is most of them.
- `scripts/normalize.sh` scans the tree with two batched greps instead of probing
  every file individually. The check takes about 1.3 seconds rather than 265, on
  a checkout of this size.

### Fixed

- **Every CI run failed at its first step, on every branch.** All 1,136 files were
  committed as mode `100644`, and the workflows invoke `scripts/foo.sh` directly,
  which on a POSIX host exits 126 with "Permission denied". The repository is
  authored on Windows, where `core.fileMode` is false and the filesystem has no
  executable bit, so git recorded `100644` for everything and nothing failed
  locally. A defect that exists only on the platform you are not developing on is
  invisible to the person best placed to fix it, and it is now checked by the
  validator rather than discovered by CI.
- `check-repo-state.sh` read the manifest version with a line-anchored pattern,
  so the check depended on the file being pretty-printed. Reformatting the
  manifest would have broken a check that has nothing to do with formatting, and
  the regression fixture caught it by writing compact JSON.
- The catalog budget guardrail changed from a flat 85 percent to an absolute
  headroom. A percentage reserve shrinks in absolute terms as the collection
  grows, even though what is being protected, room to add more skills, is a fixed
  number of characters.
- The marketplace drift and executable-bit checks moved out of
  `validate-skills.sh` into `scripts/check-repo-state.sh`. Inline checks can only
  be exercised by running the whole validator against the whole collection, which
  took minutes per assertion; the suite that resulted took nineteen minutes and is
  the reason the checks it covers were slow to notice as broken.
- Two illustrative script paths in `background-jobs-and-scheduling` and
  `git-internals` referenced files that do not exist. The validator rejects
  references to missing files precisely because an example that looks real but is
  not costs an agent a filesystem search and a wrong assumption.
- `--help` in `install.sh` and `scripts/validate-skills.sh` failed with a sed
  "Unmatched \{" error and printed nothing. It came from `\{0,\}`, which is not a
  valid interval because the minimum repetition count may not be zero.
- `install.sh --version` printed no trailing newline, so its output ran into
  whatever the shell printed next.

### Notes

- Writing `grep -q $'\r\n'` instead is worse than the original bug, and worth
  recording why: a newline inside a grep pattern splits it into two patterns, and
  the empty remainder matches every file. It reports the entire repository as
  CRLF, the obvious response is to normalise the whole tree, and nothing looks
  wrong afterwards. A detector that flags everything and one that flags nothing
  fail in opposite directions but are equally useless, and the test suite now
  pins both.

---

## [1.0.0] - 2026-10-17

First stable release. 47 skills across 12 domains, validated against the portable
Agent Skills specification and mirrored into every agent discovery convention.

### Added

**Tooling**

- `scripts/validate-skills.sh` — conformance validator for the portable
  specification, plus catalog budget, documentation drift, and encoding checks.
- `scripts/normalize.sh` — strips UTF-8 byte order marks and normalises line
  endings to LF. A BOM shifts the opening delimiter of the frontmatter and breaks
  parsing silently on some agents.
- `scripts/set-descriptions.sh` — the single auditable table of routing sentences.
- `scripts/sync-agents.sh` — mirrors the canonical source to eight discovery roots,
  comparing file content rather than names.
- `scripts/sync-rules.sh` — generates flat instruction files for the agents that
  cannot mount a skills directory, with per-agent frontmatter.
- `scripts/build-catalog.sh` — builds the remote catalog consumed by
  `skills.urls` consumers, with a description per entry for level-one disclosure.
- `scripts/build-catalog-doc.sh` — generates `docs/catalog.md` from the skills and
  their cluster assignments, failing if a skill is unassigned.
- `tests/run-tests.sh` — 17-case regression suite for the validator itself.
- `install.sh` — installs into any of fourteen agents, project or user scope.

**Skills**

23 skills covering craft and process, review, codebases, version control,
interface, accessibility, APIs, data, infrastructure, performance, security and
agent authoring.

### Security

- Enforced the **Codex catalog budget**, which was silently exceeded at 97
  percent. Codex gives the skill list 8,000 characters and omits whatever does not
  fit, so skills were being lost there without an error. All routing sentences were
  rewritten to a uniform 80 to 110 characters.
- Enforced the **Zed catalog budget** of 50 KB, discovered in its documentation.

### Fixed

- `skill://index.json` was described in earlier documentation as satisfying the
  MCP skills extension. That resource existed only in a pre-final draft and was
  removed from the final specification, which uses `skills/list` and `skills/get`
  methods instead. The collection makes no MCP compatibility claim.

### Notes

- `scripts/normalize.sh` initially normalised nothing, because bash cannot hold a
  NUL inside a string and the text-detection check therefore classified every file
  as binary.
- The validator compared temporary files by a name built from `$$`, which collided
  with the source path.