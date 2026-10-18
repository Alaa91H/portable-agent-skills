# Essential Agent Skills — Français

<!-- i18n: lang=fr clusters=18 skills=83 -->

Une collection curée et validée de **83 compétences pour agents** couvrant tout le
cycle du travail logiciel : décider quoi construire, le construire en
tests-first, le faire relire, le livrer, l'exploiter, et écrire ses propres
compétences.

Chaque compétence respecte la spécification ouverte
[Agent Skills](https://agentskills.io/specification), vérifiée par un validateur
de ce dépôt, et est répliquée dans chaque convention de découverte d'agent, afin
de fonctionner avec n'importe quel agent sans configuration.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## Ce que contient la collection

| | |
| --- | --- |
| Compétences | 83, réparties en 18 domaines |
| Agents | 14 cibles d'installation vérifiées |
| Format | Markdown brut, sans dépendance |
| Licence | MIT |

## Les domaines

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   Décider quoi faire, le faire en tests-first, et prouver que cela marche.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   Faire vérifier le travail, agir sur les retours, et le prouver sous charge.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   S'orienter, le lancer, le garder à jour, et garder sa structure tenable.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   Branches, worktrees, fusions, et la tuyauterie interne quand git surprend.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   Construire et relire des interfaces, y compris la localisation et la conformité WCAG.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   Contrats HTTP et GraphQL, versionnage, webhooks, authentification et paiements.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   Requêtes, changements de schéma, mise en cache et traitement en arrière-plan.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   Modéliser l'entrepôt, orchestrer les pipelines, et régler le calcul distribué.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   Conteneurs, orchestration, code d'infrastructure, chaînes CI, hôtes et incidents.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    Posture et coût cloud, secrets et drapeaux, pertinence de recherche, et publication mobile.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    Trouver le goulot d'étranglement, raisonner sur la concurrence, et savoir si le système va bien.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    Livrer, récupérer, planifier, et traiter les données que l'on détient sur des personnes.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    Trouver les failles exploitables dans le code, les dépendances, les en-têtes et les entrées d'agent.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    Construire sur des modèles de langage, et écrire, servir et distribuer des compétences d'agent.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    Les domaines où les défauts se cachent le mieux : journaux et horodatage.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    Écrire des garde-fous qui peuvent réellement échouer, et les primitives shell qui les portent.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    Bien dépenser une fenêtre de contexte, survivre à la compaction, et n'affirmer que ce que l'on a vérifié.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    Le dernier kilomètre : ce qui entre dans une réponse, comment c'est sourcé, et repérer un texte cassé.

## Installer pour un agent donné

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # voir les 83 identifiants
./install.sh --update            # récupérer la version la plus récente
```

## Note sur les langues des compétences

Les compétences sont en anglais, délibérément : l'agent choisit une compétence en
lisant son `name` et sa `description`, et garder ces champs identiques dans
toutes les langues est ce qui rend la collection routable quelle que soit la
langue de votre demande. Ce qui est traduit est tout ce dont un lecteur a
besoin : le cadrage, l'installation, et le contenu de chaque domaine.

Index des traductions et matrice des plateformes :
[`docs/i18n/README.md`](README.md) et [`docs/platforms.md`](../platforms.md).