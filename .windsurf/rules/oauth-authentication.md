---
trigger: model_decision
description: "Use when implementing login, tokens, sessions, or OAuth flows."
---


# Authentication and token handling

## OAuth 2.1 is a draft, not an RFC

Worth knowing before you cite it. The six changes from 2.0:

1. **PKCE is mandatory for every client**, public and confidential. In 2.0 it was
   only recommended for public clients.
2. **Redirect URIs match exactly.** No prefix or wildcard matching, with one
   exception: loopback redirect ports may vary.
3. **The implicit grant is removed** (`response_type=token`). Tokens in a URL
   fragment leak through browser history, `Referer` headers and server logs.
4. **Resource Owner Password Credentials is removed.** Never build a password
   form that posts credentials to a third-party token endpoint.
5. **Bearer tokens in query strings are removed.**
6. **Public-client refresh tokens must be sender-constrained or single-use
   rotating.**

## PKCE, mechanically

```
code_verifier    43 to 128 characters from [A-Za-z0-9-._~]
code_challenge   BASE64URL(SHA256(code_verifier))
method           S256
```

Send `code_challenge` and `code_challenge_method=S256` on the authorisation
request. At token exchange, recompute the hash from the verifier and compare
against what you stored.

- The `plain` method exists only for clients that cannot compute SHA-256.
  Never use it.
- Authorization codes must be **single-use** and short-lived, typically 60
  seconds, with 10 minutes as an absolute ceiling.
- Single-use is not optional. A replayed code is a second token issued for one
  authorisation.

## Rotate refresh tokens and detect replay

Rotate on **every** use, and record the lineage:

```
refresh-A -> refresh-B -> refresh-C
```

If `refresh-A` is presented again after it produced `refresh-B`, that is reuse.
In the legitimate world it is a retry; in the malicious world it is a stolen
token being exercised in parallel. You cannot tell which, so revoke the **entire
family** and force re-authentication.

There is a real race: two legitimate refreshes from the same client at once.
Handle it with a short grace period that replays the identical response, or by
returning `invalid_grant`. What you must not do is let both mint new tokens with
no detection.

Detect replay server-side through token family lineage. IP or device heuristics
do not work and will produce false positives that log users out.

## Sessions or JWT: the rule assistants get wrong

**For a first-party browser application, use server-side sessions with an opaque
cookie.** They are revocable. Stateless JWTs are not.

A self-contained JWT cannot be revoked before its `exp`. "Stateless" is exactly
what removes revocation. If you need revocation you must add a denylist, and at
that point you have a stateful system with extra steps and a database lookup on
every request.

| | Server-side session | JWT |
| --- | --- | --- |
| Revocation | Immediate | Denylist, or wait for expiry |
| Lookup per request | Yes | No |
| Bypass on expiry | No | Yes, until the token expires |
| Right for | Browser apps | Service-to-service, short-lived internal calls |

## Where tokens may live

| Client | Storage | Why |
| --- | --- | --- |
| Browser | `HttpOnly; Secure; SameSite=Lax` cookie | JavaScript cannot read it, so XSS cannot steal it |
| Native, mobile, desktop | OS keychain / keystore | |
| Server-to-server | Environment secret | |

**Never `localStorage` for a token.** Any XSS exfiltrates it permanently and
irreversibly. There is no refresh-token endpoint that protects you once the
access token is gone.

Cookie flags:

```
HttpOnly   not readable from JavaScript
Secure     HTTPS only
SameSite   Lax blocks most cross-site sends; Strict breaks OAuth redirects
Path=/     required for the __Host- prefix
```

The `__Host-` prefix requires `Secure`, no `Domain` attribute, and `Path=/`. It
prevents a subdomain from overwriting the cookie, which closes cookie tossing.

**Never put an access token in a URL query string.** It lands in access logs,
`Referer` headers, browser history and proxies.

## Scopes and the consent screen

Ask for the narrowest scope that works, and never request scopes at token
exchange that were not in the authorisation request. A client that asks for
`read write admin` at login teaches users to click through anything.

Verify the granted scopes are a subset of the requested ones, and check them on
every API call. A token carrying `read` that passes a check for `write` is the
most common authorisation bug in OAuth implementations.

## Revocation

RFC 7009 defines `/revoke`. In practice, access tokens are often not individually
revocable, because they were never stored. Revoke the **refresh token family**
instead, and make sure refresh tokens support revocation from the start, before
you need it.

## What not to roll yourself

Use a maintained library for the protocol mechanics. The token endpoint
handshake, PKCE verification, `state` generation and redirect validation are
exactly the code where a subtle bug is catastrophic and invisible. Write your own
authorization policy on top of it; do not write the protocol.

Always generate and verify `state` on the callback. Omitting it is a login CSRF
vulnerability, and it is the most commonly omitted check in hand-rolled flows.

## Anti-rationalisations

| Excuse | Reality |
| --- | --- |
| "JWTs scale better." | You traded revocation for it. Add a denylist and you are back to a database lookup. |
| "localStorage is fine for a SPA." | One XSS and the token is gone permanently, with no recovery. |
| "We do not have a refresh race." | Two tabs refreshing on load produce exactly that race. |
| "PKCE is only for mobile apps." | 2.1 requires it for every client, confidential ones included. |
| "Access tokens are short-lived so revocation is unnecessary." | Fifteen minutes of a compromised token is enough. Revoke the refresh family. |
