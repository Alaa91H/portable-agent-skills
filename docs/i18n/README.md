# Translations / Traducciones / Traductions / Übersetzungen

<!-- i18n-note -->

Every document below is a **translated entry point**, not a translation of the
whole repository. It carries the framing, the quick start, the install commands
and what each domain covers, in that language. The skill bodies stay in English
for three reasons, and the reasons matter more than the coverage looks:

1. **The skill descriptions are the routing layer.** An agent selects a skill by
   reading `name` and `description`. Keeping those identical across languages is
   what makes the collection routable no matter what language the user writes in.
2. **Translating them would create a second vocabulary.** Four languages means
   four ways to name the same domain, four chances for the index and the
   generator to disagree, and a drift class nobody would notice until a reader
   could not find a skill they were told existed.
3. **The bodies are instructions, not prose.** A translation that is slightly
   wrong about when to use a skill is worse than an English one that is precise,
   because the reader cannot tell it was translated.

The practical result: **a reader in any of these languages can understand the
project, install it, and know exactly what is inside.** The agent reads English
instructions regardless of the conversation language, which is what it is good at.

## Adding a language

Two steps, no code:

1. Copy any file below as `docs/i18n/<lang>.md`.
2. Translate it, keeping the two markers: the `<!-- i18n: ... -->` header and
   one `<!-- cluster: ... -->` per domain, with the cluster title in its
   canonical English form.
3. Add `<!-- lang: <lang> -->` to the list in this file.

`scripts/check-i18n.sh` then verifies the markers, the domain list and the
counts against `skills.sh.json`, so a translation that falls behind the
collection fails the build instead of quietly misleading a reader.

---

## Español

<!-- lang: es -->

1. [Español](es.md)

## Français

<!-- lang: fr -->

1. [Français](fr.md)

## Deutsch

<!-- lang: de -->

1. [Deutsch](de.md)

## Português (Brasil)

<!-- lang: pt-BR -->

1. [Português do Brasil](pt-BR.md)

## 中文

<!-- lang: zh -->

1. [简体中文](zh.md)

## 日本語

<!-- lang: ja -->

1. [日本語](ja.md)

## Русский

<!-- lang: ru -->

1. [Русский](ru.md)

## العربية

<!-- lang: ar -->

1. [العربية](ar.md) — includes a right-to-left note, because the rendering is not the same

---

## Platform coverage

Translations are language. Platforms are a separate axis, and the honest answer
is in [`docs/platforms.md`](../platforms.md): what is verified on which
operating system, which agents are verified rather than assumed, and which
distribution channels are real versus aspirational.

The short version: the skills are plain Markdown and load on any platform that
runs any AI agent. The **tooling** in this repository is where platforms differ,
and that is the part the platform document enumerates.