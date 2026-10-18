---
description: "Use when reviewing cloud IAM, network exposure, or cloud spend."
---


# Cloud security and cost

Defers to `security-code-review` for application code and
`dependency-supply-chain-review` for supply chain. This covers cloud
infrastructure: who may do what, what is exposed, and what it costs.

## IAM: delegate, do not bottleneck

Central policy authoring does not scale, and it does not know your application
intent. The mechanism that works is a **permissions boundary** as a ceiling, with
the developer authoring the policy underneath it:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["iam:CreateRole", "iam:PutRolePolicy"],
    "Resource": "*",
    "Condition": {
      "ArnEquals": { "iam:PermissionsBoundary": "arn:aws:iam::123456789012:policy/TeamBoundary" }
    }
  }]
}
```

The developer can create roles, but only ones carrying your boundary, so they
cannot exceed the ceiling. Pair it with IAM Access Analyzer, which reads CloudTrail
and generates a policy from observed access over a window. Generate it in a test
environment, since it cannot see production resources and will emit **resource
placeholders** you must fill in.

## Confused deputy is the missed condition key

Any resource-based policy granting a **service principal** access must be scoped
by where the request came from. Without it, any principal can impersonate the
service.

```json
{
  "Effect": "Allow",
  "Principal": { "Service": ["appsync.amazonaws.com"] },
  "Action": "dynamodb:GetItem",
  "Resource": "arn:aws:dynamodb:eu-west-1:123456789012:table/orders",
  "Condition": {
    "ArnEquals": { "aws:SourceArn": "arn:aws:appsync:eu-west-1:123456789012:apis/abc" }
  }
}
```

Remember that service control policies **intersect** with identity policies: an
SCP can deny an action that an identity policy allows, so a correct identity
policy still fails if the SCP does not permit it.

## The exposure findings that recur

Consistently measured across cloud security surveys, treat them as directional
and verify in your own estate:

- S3 buckets not enforcing HTTPS.
- Ingress open to sensitive ports rather than to a load balancer.
- IAM privilege escalation paths, which is the most common and most severe
  finding across providers.
- Block public access left disabled at the account level.
- Subnets auto-assigning public IPs where they should not.

The privilege-escalation number is the one that repeats across independent
sources, and it is the one worth hunting for deliberately: a principal that can
attach a policy to a role it already has `sts:AssumeRole` on can escalate to
administrator.

## Presigned URLs expire on the credential, not the clock

| Credential | Maximum validity |
| --- | --- |
| IAM user with SigV4 | **7 days** |
| Console-generated | 1 minute to 12 hours |
| IAM role session | The **role session duration**, often 6 hours |
| Temporary credentials | The credential's own lifetime |

A presigned URL **expires as soon as the credential used to sign it is revoked,
deleted or deactivated**, even if it was created with a later expiry. A URL
generated from a role session dies with the session.

They are bearer tokens: anyone holding one has access. And uploading with the
same key **replaces** the object.

Cap the window with the signature-age condition key, in milliseconds:

```json
{
  "Effect": "Deny", "Principal": { "AWS": "*" }, "Action": "s3:*",
  "Resource": "arn:aws:s3:::bucket/*",
  "Condition": { "NumericGreaterThan": { "s3:signatureAge": "600000" } }
}
```

## Serverless: pick the cost lever from the init time

The decision rule is the init time, not the traffic.

- **If the function initialises in hundreds of milliseconds**, a snapshot-based
  warm start will not help much. Use provisioned concurrency for double-digit
  millisecond cold starts.
- **If it initialises in seconds**, a warm-start snapshot is the cheaper lever
  and gets you sub-second starts.

Provisioned concurrency is billed from enable until disable, **rounded up to
five minutes, and billed while idle**, so five always-warm instances costs real
money every hour they sit unused. Model that before enabling it.

## Other cost traps

- Data transfer between availability regions and between NAT gateways is
  routinely the largest line item and the least visible. Meter it explicitly.
- Log retention defaults are usually generous. The default retention, not your
  usage, sets the bill.
- Idle provisioned capacity looks like zero utilisation and bills full price.
- Autoscaling on a metric that is low at baseline means minimum capacity is the
  real cost.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "Only the security team writes policies." | That is the bottleneck. Give them a boundary and let developers author underneath it. |
| "The role is trusted, no condition needed." | Without `aws:SourceArn`, any principal can impersonate the service. |
| "The policy allows it, so it works." | SCPs intersect with identity policies and can deny regardless. |
| "The presigned URL is valid for a week." | It dies when the signing credential is revoked or the session ends. |
| "Provisioned concurrency is cheap." | It bills while idle, from enable until disable. |
| "Compute is our biggest cost." | Cross-region transfer and NAT gateway fees frequently exceed it. |
