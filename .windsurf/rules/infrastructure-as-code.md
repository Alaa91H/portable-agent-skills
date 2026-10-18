---
trigger: model_decision
description: "Use when writing Terraform or other infrastructure code, managing cloud resources declaratively, or diagnosing drift between code and a live environment."
---


# Infrastructure as code

## State is the hard part, not the syntax

The syntax is memorised. The problems that bite are state:

- **State contains secrets.** A Terraform state file often holds database
  passwords in plaintext, because that is what the API returned. Store it in a
  backend with encryption at rest and strict access, never in git.
- **Back it up before every operation.** `terraform state pull` is the safety
  net; without it, a bad apply has no recovery path.
- **Never edit state by hand** except under `terraform state mv` or `rm`. Hand
  editing desynchronises the graph.
- **One state per environment.** A shared state across environments couples them
  so thoroughly that a plan in staging produces a production diff.
- **Lock it.** Concurrent applies corrupt state. Every major backend has
  locking; do not disable it.

## Plan is the review artefact

```sh
terraform plan -out=tfplan
terraform show tfplan          # this is the reviewable artefact
terraform apply tfplan
```

`terraform plan` output is not stable enough to read directly and is not
reviewable in a pull request. Use machine-readable JSON in CI and render the
plan into the pull request comment, so a reviewer sees what will change before
merge:

```sh
terraform show -json tfplan | jq -r '.resource_changes[] |
  select(.change.actions != ["no-op"]) |
  "\(.address)  \(.change.actions | join(","))  \(.change.after | tostring)"'
```

Reviewing a plan catches the things that matter: a resource being **replaced**
when it should be updated in place, and a **destroy** that nobody intended. Both
are common and both are invisible in the diff, because the diff only shows the
code change.

## Drift detection is a separate job from apply

Apply makes code match reality at apply time. Drift happens afterwards:
someone fixes production by hand, a console default changes, a tag moves.

```sh
terraform plan -detailed-exitcode   # 0 no drift, 2 drift, 1 error
```

Run it on a schedule and alert on exit code 2. Hand-edited production is the
single largest cause of "the next apply destroyed something unexpected".

## Modules are a contract

- **A module should have one responsibility.** A module named `network` that
  also creates databases has two reasons to change.
- **Inputs and outputs are the public API.** Renaming an input is a breaking
  change for every consumer, exactly as in `api-contract-versioning`.
- **Do not pass in every provider argument.** A module that exposes thirty
  optional arguments reimplements the provider, and nobody can read the result.
- **Do not hide required structure.** A module that cannot be created wrongly is
  worth more than one that is flexible.
- Pin module sources by **version and ideally digest**, never a branch or a
  moving tag. The supply chain argument in
  `dependency-supply-chain-review` applies identically here.

## Never put secrets in code

```hcl
# Wrong: readable by everyone with repo access, and in git history forever
variable "db_password" { default = "hunter2" }

# Right: sourced at run time from a secret manager
data "aws_secretsmanager_secret_version" "db" { secret_id = var.db_secret_id }
```

The rule is the same as for application secrets, and it also applies to CI
outputs, which get logged.

Use a secret manager and reference the value. If it must be in Terraform, use a
mechanism that never persists plaintext in state, and know that most providers
will write the value to state regardless.

## Destroy needs more care than apply

`terraform destroy` is the most dangerous command in the workflow, and it is one
typo away.

- Require the destroy plan to be **reviewed as carefully as an apply**, and
  approve it explicitly.
- Protect production with a state lock plus an approval step.
- **Use `prevent_destroy` on anything whose loss is unrecoverable**, such as a
  production database or an object store. It is a lifecycle block:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Deleting a state-backed database does not empty it, it makes it **impossible to
recreate with the same data**. That distinction catches people every time.

- Consider `terraform plan -destroy` to see the full impact before committing to
  it.

## Remote state and locking

```hcl
terraform {
  backend "s3" {
    bucket         = "acme-tfstate"
    key            = "prod/network/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "acme-tflock"   # locking, if this backend version needs it
  }
}
```

Native locking is available on current S3 and most other backends. Whichever you
use, **locking is not optional**; two concurrent applies corrupt state in ways
that are painful to recover from.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "It is only infrastructure." | It has state, secrets and a destroy button. It deserves more care, not less. |
| "We will keep the password in a variable." | It ends up in git history and in the state file. Use a secret manager. |
| "The plan output is fine to read." | Use `show -json` and render it. Replacements and destroys are the review point. |
| "Nobody edits production by hand." | Then run drift detection to find out, rather than believing it. |
| "Destroy is fine, we have backups." | Restore time is not zero, and a destroyed bucket cannot be restored from a backup. |
