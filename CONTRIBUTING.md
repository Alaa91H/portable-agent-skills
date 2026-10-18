# Contributing

## Add a skill

1. Read `docs/authoring.md`. It is the contract, and the validator only enforces
   the mechanical half of it.
2. Check `docs/catalog.md` for whether the skill already exists under another
   name. Two skills that trigger on the same situation is a defect.
3. Create `.opencode/skills/<skill-id>/SKILL.md`, where `<skill-id>` is
   lowercase kebab-case. `name` in the frontmatter must equal the directory name.
4. Add a row to `docs/catalog.md`.
5. Run the checks below.
6. Run `scripts/sync-agents.sh` to propagate the skill to every agent
   discovery root, and commit the generated copies.

## Before you commit

```sh
scripts/normalize.sh        # strip UTF-8 BOM, force LF
scripts/validate-skills.sh  # spec conformance
scripts/sync-agents.sh      # propagate to every discovery root
tests/run-tests.sh          # the validator still works
```

CI runs all four plus a catalog build, with `--strict`, so warnings fail the
build.

## Before you open a review

The validator cannot tell you whether a skill is *good*. Apply the harder
standard: run an agent on a representative task **without** your new skill,
record what it does wrong, and confirm the skill changes that behaviour. The
procedure is in `.opencode/skills/writing-agent-skills/references/eval-protocol.md`.

## Rules worth restating

- **The description decides whether the skill ever loads.** It is the only part
  in context at every model step. Describe the trigger surface, never the
  workflow.
- **Do not summarise the procedure in the description.** An agent that already
  has the plan will not open the file.
- **Match the form to the failure.** Prohibitions for rules that get skipped
  under pressure; positive recipes for output that has the wrong shape.
- **References one level deep.** An agent reading a file that points at another
  file may preview it and act on a partial read.
- **Say whether to run a script or read it.** Ambiguity makes the agent read
  code it should have executed.
- **Do not document what a validator could enforce.** Automate it instead.

## Editing an existing skill

Treat a description change the same as any other behavioural change. It alters
when the skill fires for every future session, so say in the pull request which
triggers become more or less likely.

Do not add a rule for a situation you have not observed failing. Skills that grow
by speculation become walls that nobody reads.

## Generated files

`.claude/skills`, `.agents/skills`, `.github/skills` and `skills` are generated
from `.opencode/skills` by `scripts/sync-agents.sh`. Edit the canonical copy
only. CI fails if they drift.