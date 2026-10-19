# Security policy

## Scope

This repository is a collection of Markdown files and shell scripts. There is
no server, no database, no authentication, and nothing that runs on a user's
machine without their choosing to run it.

The things worth reporting are therefore narrow but real:

- A script that does something other than what its documentation says.
- A script that writes outside the directories it names, or follows a path it
  was not given.
- A skill whose content would lead an agent to do something unsafe, or to
  disclose data it was told not to disclose.
- A dependency or workflow reference that would pull in unverified code.

## Reporting

Open a **private** security advisory on this repository rather than a public
issue. The Security tab above the code has a "Report a vulnerability" button.

Include what you ran, what you expected, and what happened instead. If you
found it by reading rather than by running, say so: a reading-based report is
still useful, and it is easier to act on than a speculative one.

There is no formal response-time commitment, because this is a volunteer
project with no funding behind it. In practice, a confirmed defect in a script
is fixed in the next commit, and a fix that changes a script's behaviour is
called out in `CHANGELOG.md`.

## What is not a vulnerability

- A skill giving advice you disagree with. That is a discussion.
- A claim in a skill being wrong or outdated. That is a bug report, and it is
  welcome; several exist in this repository's own history.
- The collection's skill descriptions exceeding a client's context budget. That
  is a known and documented limit, it is checked by `scripts/validate-skills.sh`,
  and it is not a security issue.
- A typo. Please still report it; it is only not a *security* issue.

## What the repository does about scripts

Every script in `scripts/` is exercised by `tests/run-tests.sh`, and the
regression suite is run on every push. The suite plants deliberate defects and
requires the corresponding gate to fail, because a gate that has never been
seen failing is not known to work.

Workflow actions are pinned to commit SHAs rather than tags, and
`dependabot.yml` keeps those pins current. A tag can be moved after you have
reviewed it; a commit cannot.
