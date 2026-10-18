# Platform support

This document exists because "works everywhere" is a claim, and a claim without a
matrix is marketing. It states what is **verified**, what is **structural**, and
what is **not true yet**.

The short version: the **skills** are platform-independent by construction. The
**tooling** in this repository is not, and this is where the platform differences
are.

---

## 1. The skills

| Property | Status |
| --- | --- |
| Format | Plain Markdown files with YAML frontmatter |
| Runtime dependency | None. No build step, no package manager |
| Encoding | UTF-8, LF line endings, no BOM |
| Line length | No assumption; no file exceeds the 500-line guidance in the spec |
| Operating system | Independent. A skill is a file that a model reads |
| Language | Skill bodies are English by design, see [`i18n/README.md`](i18n/README.md) |

A skill loads anywhere an agent can read a file, which includes every platform
this repository has never heard of. There is nothing in the format that could
bind it to one.

## 2. Agent discovery

### Verified install targets

`install.sh` has an explicit target for each of these, and the paths are taken
from each agent's own documentation rather than guessed:

| Agent | Project | User |
| --- | --- | --- |
| OpenCode | `.opencode/skills` | `~/.config/opencode/skills` |
| Claude Code | `.claude/skills` | `~/.claude/skills` |
| Spec clients | `.agents/skills` | `~/.agents/skills` |
| GitHub Copilot | `.github/skills` | `~/.github/skills` |
| Cursor | `.cursor/skills` | `~/.cursor/skills` |
| Windsurf / Devin | `.devin/skills` | `~/.codeium/windsurf/skills` |
| Cline | `.cline/skills` | `~/.cline/skills` |
| Roo Code | `.roo/skills` | `~/.roo/skills` |
| JetBrains Junie | `.junie/skills` | `~/.junie/skills` |
| Kilo Code | `.kilo/skills` | `~/.kilo/skills` |
| Trae | `.trae/skills` | `~/.trae/skills` |
| Augment | `.augment/skills` | `~/.augment/skills` |
| Gemini CLI | `.gemini/skills` | `~/.gemini/skills` |
| OpenAI Codex | `.codex/skills` | `~/.codex/skills` |

The `.agents/skills` row is the important one. It is the convention the open
[Agent Skills specification](https://agentskills.io/specification) defines, so
any client that follows the specification reads it, including clients released
after this table was written. **That row does not go stale.**

### Agents that cannot read a skills directory

Some agents read flat instruction files rather than a directory of skills. For
these the repository generates one rule file per skill, with that agent's own
frontmatter keys, in 471 files across 14 conventions:

`.cursor/rules` (`.mdc`), `.roo/rules`, `.windsurf/rules` (with
`trigger: model_decision`), `.devin/rules`, `.cline/rules`, `.trae/rules`,
`.clinerules`, `.continue/rules`, `.goose`, `.rules`, `.amazonq/rules`,
`.augment`, plus root-level `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
`CONVENTIONS.md`, `.cursorrules`, `AmazonQ.md` and `TABNINE.md`.

`alwaysApply` is deliberately left `false` and the Windsurf trigger is
`model_decision`, because a rule that is always applied destroys progressive
disclosure, which is the property that makes a large collection usable at all.

### Distribution channels

| Channel | Status |
| --- | --- |
| Local checkout | Real. This repository |
| `npx skills add Alaa91H/portable-agent-skills` | Real, project or global |
| Claude plugin marketplace | Real. `.claude-plugin/marketplace.json` |
| HTTP catalog at `dist/index.json` | Real. Built by `scripts/build-catalog.sh`, served by any static host |
| MCP `skills/list` and `skills/get` | Real per the current specification |
| **MCP `skill://index.json` resource** | **Not real.** It existed in a pre-final draft and was removed. This repository makes no claim to it |

That last row is the only place where neutrality is actively asserted against a
possibility, and it is worth keeping. A claim that would have been true for most
of the specification's life is the kind of thing that ends up in a README and
outlives its truth.

## 3. The tooling, and where it actually differs

The scripts assume a POSIX shell and the usual GNU tools. They are developed and
run on Windows through Git Bash and on Linux through CI. **Five defects in this
repository were platform-specific and invisible to the platform they were
written on.** They are listed because the pattern matters more than the list.

### Executable bit

Every script was committed as mode `100644`, so every CI run failed at its first
step with `Permission denied`. The repository is authored on Windows, where
`core.fileMode` is false and the filesystem has no executable bit, so `chmod`
does nothing and git records the mode silently. **A defect that exists only on
the platform you are not developing on is invisible to the person best placed to
fix it.** It is now checked by `scripts/check-repo-state.sh` and the check is
tested by planting the drift.

### Line endings and encoding

`grep -q $'\r'` never matches a carriage return, because grep consumes the
trailing CR as part of the pattern's terminator. The CRLF gate reported
"everything is already normalized" for the entire life of the project while being
structurally incapable of finding anything.

The naive fix is worse: `grep -q $'\r\n'` matches **everything**, because a
newline inside a pattern splits it and the empty remainder matches any file. It
reports the whole repository as defective, the obvious response is to normalise
all of it, and afterwards nothing looks wrong. Correct form is `grep -qU $'\r'`.

A UTF-8 BOM is emitted by PowerShell's default encoding and shifts the opening
`---` of the frontmatter, breaking parsers silently. `.gitattributes` pins
`eol=lf` and `scripts/normalize.sh` enforces it.

### Silent write failures

`INDEX_FILES` was colon-separated while the loop splits on whitespace, so the six
index mirrors for Cline, Continue, Goose, Amazon Q and Augment were never written
at all, and the gate was checking one nonexistent path and reporting agreement.
The root cause was that a redirect to a missing directory discarded its status.

### Per-file subprocesses

Probing every file individually cost eight processes per file, which on a
thousand-file checkout was 265 seconds against 1.3 seconds for two batched greps.
This one is worth knowing about on every platform.

### Argument passing across a wrapper

`bash "script.sh --check"` hands bash one string containing a space, which it
treats as a filename, and the failure reads `No such file or directory` rather
than anything mentioning arguments. It bites hardest when a shell script is driven
from PowerShell or another layer that re-quotes.

## 4. What is not claimed

- **No MCP compatibility claim for a removed resource.** See the table above.
- **No guarantee that every agent listed in the spec has a working installer.**
  The installer covers the fourteen targets above; other spec clients read
  `.agents/skills` directly, which is why that mirror is committed and checked.
- **No Windows-native build of the scripts.** They require a POSIX shell. On
  Windows that means Git Bash, WSL, or a CI runner. This is a real limitation,
  not a preference.
- **No support for models with very small context windows**, where a
  seventy-nine skill catalogue will not fit. The validator enforces the limit and
  the honest answer for that case is to install a subset with
  `./install.sh <agent> --only <ids>`.