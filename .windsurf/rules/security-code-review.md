---
trigger: model_decision
description: "Use when reviewing code that handles untrusted input, auth, secrets, or file access."
---


# Security code review

## Work from the trust boundary inward

Start where untrusted data enters, and follow it to every place it lands. A
review that reads files looking for suspicious syntax misses the defect that is
not suspicious-looking.

```sh
# Where does untrusted data enter?
grep -rnE "req\.(body|query|params|headers)|request\.(json|form|args)|process\.argv|stdin" src/

# What are the sinks it can reach?
grep -rnE "exec|spawn|eval|query\(|raw\(|createReadStream|redirect\(|innerHTML|dangerouslySetInnerHTML|deserialize|pickle" src/
```

Trace each entry to each sink and ask, at the boundary: what makes this input
trustworthy? If the answer is a validation that does not exist, that is a finding.

## Sinks and what each requires

| Sink | Requires | The failure |
| --- | --- | --- |
| `exec`, `spawn` with shell | Argument array, never string interpolation | `userId` in a shell string is remote code execution |
| SQL `query`, `raw` | Parameterised query | String concatenation is injection |
| File `readFile`, `createReadStream` | Path resolved and confirmed inside an allowed root | `../../etc/passwd` and absolute-path bypass |
| Template rendering | Contextual auto-escaping | Unescaped interpolation is XSS |
| `redirect(url)` | Allowlist of destinations | Open redirect enables phishing and token theft |
| `JSON.parse` of user input | Schema validation after parsing | An object where a scalar was assumed is a prototype-pollution vector |
| `unserialize`/deserialise | Never, for untrusted data | Arbitrary object construction |
| Regex built from input | Never | Catastrophic backtracking is a denial of service |

## Authentication versus authorisation

These are separate and are confused constantly:

- **Authentication** asks who this is. **Authorisation** asks what they may do.
  A correct login does not imply a correct permission check.
- **IDOR** is the most common authorisation defect: the handler fetches
  `resourceId` from the request and loads it without checking ownership.

```ts
// Vulnerable: any authenticated user reads any invoice
const invoice = await db.invoice.findUnique({ where: { id: req.params.id } })

// Correct: ownership is part of the query
const invoice = await db.invoice.findFirst({
  where: { id: req.params.id, ownerId: req.user.id },
})
if (!invoice) return res.status(404).send()
```

Scoping the query is stronger than checking afterwards, because it cannot be
forgotten on a new code path.

## Secrets

```sh
grep -rnE "(api[_-]?key|secret|password|token)\s*[:=]\s*['\"][^'\"]{8,}" src/ --include=*.ts --include=*.js
git log -p -S "API_KEY" -- . | head -50     # history, not just the working tree
```

A secret committed once is compromised, whether or not it is removed later;
rotating is the fix and removal is hygiene. Check the history, not just the
current tree.

Never log a secret, a full card number, an auth header, or a password reset
token. Redact at the serialisation layer rather than remembering at each call
site.

## Findings must carry an exploit path

The difference between a useful security review and a generic warning is
specificity. Every finding needs:

1. **The entry point.** Where the attacker-controlled data enters.
2. **The path.** The concrete call chain to the sink.
3. **The payload.** The exact input that triggers it.
4. **The impact.** What the attacker gets.
5. **The fix.** The specific change, not "validate input".

```markdown
Title: Path traversal in report download
Entry:  GET /api/reports?path=...   (src/routes/reports.ts:22)
Sink:   fs.readFile(req.query.path) (src/routes/reports.ts:34)
Payload: /api/reports?path=../../../../etc/shadow
Impact: arbitrary file read as the service user
Fix:    resolve and verify the path is inside REPORT_ROOT before reading
```

Sort by impact against what the attacker gains, not by how many lines the fix
touches.

## What not to do

- Do not report a finding whose exploit path you have not traced. "This could be
  vulnerable if the input is not validated" is noise unless you checked.
- Do not propose a fix you have not verified closes the path.
- Do not report the absence of a security header as equivalent to an injection.
  Rank real defects above hygiene, or the real ones get triaged away.

## Limits worth stating

Say when the review does not cover something: the dependency tree, the deployed
infrastructure, the runtime configuration, or the infrastructure-as-code. Those
are separate reviews, and a code review claiming to have covered them is
overstating what was checked.
