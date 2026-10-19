# Pull request

## What this changes

<!--
One or two sentences. If it fixes an issue, put the number at the end of the
first line so it closes automatically.
-->

## Why

<!--
The reasoning, not the diff. A reviewer reads the diff anyway.
-->

## How it was checked

<!--
Which gates you ran, and what they printed. If you planted a defect to prove
a gate can fail, say so and show the failure.
-->

```sh
scripts/validate-skills.sh --strict
tests/run-tests.sh
```

## Checklist

- [ ] `scripts/validate-skills.sh --strict` passes
- [ ] `tests/run-tests.sh` passes
- [ ] `scripts/normalize.sh --check` reports nothing to normalise
- [ ] A new or changed skill was checked against the Agent Skills specification
- [ ] Any new gate was proven to fail when its defect is planted
- [ ] `CHANGELOG.md` has an entry, if this is user-visible
- [ ] No temporary artefacts (`*.tmp.*`) are staged

## Notes for the reviewer

<!--
Anything you would have found by reading the diff and would rather explain
than have the reviewer work out.
-->
