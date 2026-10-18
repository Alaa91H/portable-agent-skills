---
name: email-deliverability
description: Use when sending email, or configuring SPF, DKIM or DMARC records.
---

# Email deliverability

## Three records, three jobs

Authentication is not one setting. A message passes when the **sending domain is
authorised**, the **content is signed**, and the **two agree**.

| Record | Purpose | Lives at |
| --- | --- | --- |
| SPF | Which hosts may send as this domain | TXT at the domain apex |
| DKIM | Content signature proving it was not altered | TXT at `<selector>._domainkey.<domain>` |
| DMARC | What to do when SPF and DKIM disagree | TXT at `_dmarc.<domain>` |

## SPF

```
example.com. TXT "v=spf1 +mx a:colo.example.com/28 -all"
```

- **Exactly one SPF record per domain.** Publishing two is a permanent error and
  receivers will ignore both. Check for legacy records before adding one.
- The record must fit **one DNS packet**, so roughly 450 characters. Long
  `include:` chains are the usual cause of failure, and the DNS lookup budget is
  **10 queries** per evaluation.
- Terminators: `-all` reject, `~all` softfail, `?all` neutral. There is an
  implicit `?all` if you omit one, which means "nobody is validating", so state
  it explicitly.
- Use `include:` for services you delegate to. Avoid `ptr` entirely; it is slow
  and unreliable.
- Check it with a real evaluator rather than guessing:

```sh
dig +short TXT example.com
```

## DKIM

```
brisbane._domainkey.example.com. TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSq..."
```

- The record is **CNAME-able**, which is how mail providers share keys across
  domains. If your provider gives you a selector and a CNAME target, create the
  CNAME rather than copying the key.
- `p=` may be empty, which revokes the key. Use that to disable signing while
  keeping the selector reserved.
- 2048-bit keys are around 294 characters of base64, which exceeds one TXT
  string, so the value is split across quoted chunks. Publishing it as one
  unbroken string is a common and silent failure.

## DMARC

```
_dmarc.example.com. TXT "v=DMARC1; p=none; rua=mailto:dmarc@example.com; pct=100"
```

- **Roll the policy up gradually.** `p=none` with `rua` collects reports and
  changes nothing. Only move to `quarantine`, then `reject`, once the reports
  show every legitimate sender is aligned.
- `rua` is aggregate reporting. It will accept messages from anywhere, so do
  not treat a working `rua` as proof of alignment.
- Start at `pct=10` before `pct=100` so a mistake damages 10 percent of mail
  rather than all of it.
- `rua` supports a size limit with `!`, where the unit is a **power of two**:
  `mailto:reports@example.com!50m`.
- To have an external service receive reports, it needs its own opt-in record:
  `example.com._report._dmarc.thirdparty.net. TXT "v=DMARC1"`.

## Alignment is the part people get wrong

DMARC passes when **either** SPF or DKIM passes **and is aligned** with the
visible `From:` domain. Failing authentication on both is irrelevant if one is
aligned and valid.

```
From: sender@child.example.com
DKIM d=example.com          <- parent domain
```

This is **relaxed alignment** and it passes. Under `adkim=s` (strict) it fails,
because strict requires an exact organisational-domain match.

Use `aspf=r` and `adkim=r` (the defaults) unless you genuinely control every
subdomain.

## One-click unsubscribe, RFC 8058

Required for bulk commercial mail. The five normative requirements, each of
which is skipped somewhere:

```
List-Unsubscribe: <https://example.com/unsubscribe/opaquepart>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

1. `List-Unsubscribe` must contain **at least one HTTPS** URI.
2. `List-Unsubscribe-Post` must contain **exactly** `List-Unsubscribe=One-Click`.
3. The message must have a **valid DKIM signature covering both headers**, which
   means both must appear in the signature's `h=` tag. Without that, receivers
   are right to ignore the header.
4. The URL must be **opaque**, so an attacker cannot use your endpoint to
   mass-unsubscribe your list from their own spam.
5. The POST endpoint must **not redirect**, and must not depend on cookies or
   session state.

Your endpoint receives:

```sh
curl -X POST 'https://example.com/unsubscribe/opaquepart' \
  -d 'List-Unsubscribe=One-Click'
```

Return 200 and unsubscribe. Transactional mail is exempt: password resets,
receipts and security alerts do not need this.

## Bounces and complaints

| Signal | Meaning | Action |
| --- | --- | --- |
| Hard bounce (5xx) | Address invalid | Suppress permanently |
| Soft bounce (4xx) | Full mailbox, greylisting | Retry with backoff, track cumulatively |
| **Complaint** | Delivered, marked spam | **Revoke consent, never retry** |

A complaint is a far stronger signal than a bounce, and retrying to a complainer
is the fastest way to lose a sending reputation.

Track soft bounces in consecutive windows and suppress on the third consecutive
one; recover the address after a long successful period.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "SPF authenticates our mail." | It says which hosts may send. It does not prove the content is ours. |
| "We have one SPF record already." | Two is a configuration error; check before adding a second. |
| "DMARC p=none is set, so we are protected." | `p=none` only collects reports. It changes no delivery outcome. |
| "We will move to reject after verifying." | Verify with reports first, at `pct=10`, for at least a full sending cycle. |
| "The unsubscribe link is a GET." | Receivers POST to it, and a redirect breaks the POST. |
| "One-click is for marketing only." | It is required for bulk commercial mail, and transactional mail is exempt. |
