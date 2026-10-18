# Essential Agent Skills — Deutsch

<!-- i18n: lang=de clusters=18 skills=84 -->

Eine kuratierte, validierte Sammlung von **84 Agent-Skills** für den gesamten
Bogen der Softwarearbeit: entscheiden, was gebaut wird, test-first bauen,
reviewen lassen, ausliefern, betreiben — und eigene Skills schreiben.

Jeder Skill folgt der offenen
[Agent-Skills-Spezifikation](https://agentskills.io/specification), wird von
einem Validator in diesem Repository geprüft und in jede Agent-Discovery-Konvention
gespiegelt, damit er ohne Konfiguration mit jedem Agenten funktioniert.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## Was enthalten ist

| | |
| --- | --- |
| Skills | 84, in 18 Domänen |
| Agenten | 14 verifizierte Installationsziele |
| Format | einfaches Markdown, keine Abhängigkeiten |
| Lizenz | MIT |

## Die Domänen

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   Entscheiden, was zu tun ist, es test-first umsetzen und den Erweis führen.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   Arbeit prüfen lassen, auf Rückmeldung reagieren, und unter Last belegen.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   Sich orientieren, es zum Laufen bringen, aktuell halten und die Struktur handhabbar halten.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   Branches, Worktrees, Merges — und die Rohrpost darunter, wenn git überrascht.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   Interfaces bauen und prüfen, einschließlich Lokalisierung und WCAG-Konformität.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   HTTP- und GraphQL-Verträge, Versionierung, Webhooks, Authentifizierung, Zahlungen.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   Abfragen, Schemaänderungen, Caching und Hintergrundverarbeitung.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   Das Warehouse modellieren, Pipelines orchestrieren, verteilte Rechenlast abstimmen.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   Container, Orchestrierung, Infrastrukturcode, CI-Strecken, Hosts und Vorfälle.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    Cloud-Haltung und Kosten, Secrets und Flags, Suchrelevanz und Mobile-Release.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    Den Engpass finden, über Nebenläufigkeit nachdenken, und wissen, ob das System gesund ist.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    Ausliefern, wiederherstellen, planen, und mit den Daten umgehen, die über Menschen gespeichert sind.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    Ausnutzbare Fehler finden — in Code, Abhängigkeiten, Response-Headern und Agent-Eingaben.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    Auf Sprachmodellen aufbauen, und Agent-Skills schreiben, bereitstellen und verteilen.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    Die Domänen, in denen sich Fehler am besten verstecken: Logs und Zeitstempel.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    Prüfungen schreiben, die wirklich scheitern können, samt der Shell-Primitiven darunter.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    Ein Kontextfenster gut ausnutzen, Kompaktierung überstehen, und nichts behaupten, was nicht geprüft ist.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    Die letzte Meile: was in eine Antwort gehört, wie es belegt wird, und defekten Text erkennen.

## Für einen bestimmten Agenten installieren

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # die 84 Kennungen anzeigen
./install.sh --update            # neueste Version holen
```

## Hinweis zur Sprache der Skills

Die Skills sind bewusst englisch: der Agent wählt einen Skill anhand von `name`
und `description`. Diese Felder in allen Sprachen identisch zu halten ist genau
das, was die Sammlung unabhängig von der Sprache der Anfrage routbar macht.
Übersetzt ist alles, was ein Leser braucht: der Rahmen, die Installation und der
Inhalt jeder Domäne.

Übersetzungsindex und Plattformmatrix:
[`docs/i18n/README.md`](README.md) und [`docs/platforms.md`](../platforms.md).