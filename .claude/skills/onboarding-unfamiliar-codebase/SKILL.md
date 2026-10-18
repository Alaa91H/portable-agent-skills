---
name: onboarding-unfamiliar-codebase
description: Use when opening an unfamiliar repository, or orienting in one.
---

# Onboarding an unfamiliar codebase

## Orient before you read anything

```sh
ls -la                       # layout, and whether this is a monorepo
cat README.md AGENTS.md 2>/dev/null | head -60
git log --oneline -30        # what has been changing, which is usually the interesting part
git log --format='%an' -200 | sort | uniq -c | sort -rn | head   # who knows this code
find . -name '*.lock' -o -name 'package.json' -o -name 'pyproject.toml' \
     -o -name 'go.mod' -o -name 'Cargo.toml' | grep -v node_modules | head -20
```

Twenty minutes of orientation saves hours of reading the wrong file. Build
membership and recent churn predict relevance far better than directory names.

## Find the entry points

```sh
grep -rnE 'if __name__|app\.listen|createServer|func main\(|@main|spring.application' \
  --include='*.py' --include='*.ts' --include='*.go' --include='*.java' . | head
```

Then work backwards from an entry point to the business logic, because that path
is guaranteed to be executed and therefore guaranteed to be real. Directory
structure describes intent; the call path describes reality.

## Map the shape with evidence, not impression

```sh
# Where the complexity actually is
git log --since=6.months --format= --name-only | sort | uniq -c | sort -rn | head -20

# Which files change together; these are the real module boundaries
git log --since=1.year --name-only --format= | grep -v '^$' | sort | uniq -c | sort -rn | head -30
```

Co-change frequency is the most reliable architecture signal available without
reading the code. Files that always change together are one concept, whatever
the directory layout says.

## Read tests before production code

Tests are the specification that someone already wrote down, and they are honest
because they fail when behaviour breaks.

```sh
ls **/tests/** **/__tests__/** test/ spec/ 2>/dev/null | head -20
```

Read two or three. You learn the domain vocabulary, the intended entry points,
and the edge cases someone cared about, without reading a line of implementation.

## Build a map you can check

A short written map beats an extensive mental one:

```markdown
## What this is
One paragraph, in the project's own vocabulary.

## Shape
- `packages/api` - HTTP layer, thin, validates and delegates
- `packages/core` - domain logic, no I/O, most tests live here
- `packages/web` - Next.js frontend

## The three things to know before changing anything
1. ...
2. ...
3. ...

## Where the risk is
- <file>: 4,000 lines, changes monthly, two owners
- migrations/: expand/contract only, see the runbook
```

Write it down where the next person will find it. A map that lives only in one
context window is lost the next time the window is cleared.

## Ask what the tests and history say about the risky parts

Three questions with commands, and they answer most of what you need to know:

1. **What breaks often?** `git log --grep='fix' --since=1.year --format='%s' | sed 's/#\([0-9]*\).*//' | sort | uniq -c | sort -rn | head`
2. **What was hard to design?** `git log --merges --oneline | head -20` — merge
   commits are where structural decisions got made.
3. **What has nobody touched in two years?** `git log --since=2.years --name-only --format= | sort | uniq -c | sort -rn | head -30`, inverted. It is either stable or abandoned, and both are worth knowing.

## Do not do these things first

- Do not read every file. Read the entry point, the tests, and the highest-churn
  module.
- Do not refactor anything you do not yet understand.
- Do not assume the directory layout is accurate. Generated code and abandoned
  directories are common.
- Do not install the full toolchain before knowing what runs. That is
  `environment-bootstrap`, and it has its own skill.

## Report back what you found

Orientation is only useful if it is communicated. State the shape, the three
things that matter, and the risk areas, in that order and in under a page. A
newcomer who has to ask the same question twice has not been onboarded.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "I will read the code and understand it." | Churn analysis will point at the important parts in five minutes. |
| "The README explains the architecture." | It explains the intent. The call graph and churn describe reality. |
| "I do not need to read tests first." | They are the specification, and they are honest because they fail. |
| "This codebase is small enough." | Then you did not need a skill, and reading it end to end is faster anyway. |
| "I will figure out the architecture as I edit." | You will change something load-bearing and find out from an incident. |
