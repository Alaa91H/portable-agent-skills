# Essential Agent Skills — Español

<!-- i18n: lang=es clusters=18 skills=84 -->

Una colección curada y validada de **84 habilidades para agentes** que cubren
todo el ciclo del trabajo de software: decidir qué construir, construirlo con
pruebas primero, someterlo a revisión, publicarlo, operarlo, y escribir
habilidades propias.

Cada habilidad cumple la especificación abierta
[Agent Skills](https://agentskills.io/specification), verificada por un
validador en este repositorio, y reflejada en cada convención de descubrimiento
de agentes, para que funcione con cualquier agente sin configuración.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## Qué incluye

| | |
| --- | --- |
| Habilidades | 84, en 18 dominios |
| Agentes | 14 destinos de instalación verificados |
| Formato | Markdown plano, sin dependencias |
| Licencia | MIT |

## Los dominios

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   Decidir qué hacer, hacerlo con pruebas primero, y demostrar que funciona.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   Someter el trabajo a revisión, actuar sobre los comentarios, y probarlo bajo carga.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   Orientarse, ponerlo en marcha, mantenerlo actualizado y mantener su estructura manejable.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   Ramas, worktrees, fusiones, y la fontanería interna cuando git te sorprende.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   Construir y revisar interfaces, incluida la localización y el cumplimiento de WCAG.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   Contratos HTTP y GraphQL, versionado, webhooks, autenticación y pagos.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   Consultas, cambios de esquema, cachés y procesamiento en segundo plano.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   Modelar el almacén analítico, orquestar flujos y ajustar el cómputo distribuido.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   Contenedores, orquestación, código de infraestructura, flujos de CI, hosts e incidencias.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
   Postura y coste en la nube, secretos y banderas, relevancia de búsqueda, y publicación móvil.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
   Encontrar el cuello de botella, razonar sobre concurrencia, y saber si el sistema está sano.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    Publicar, recuperar, programar, y tratar los datos que guardas sobre personas.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    Encontrar defectos explotables en código, dependencias, cabeceras de respuesta y entradas de agente.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    Construir sobre modelos de lenguaje, y escribir, servir y distribuir habilidades de agente.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    Los dominios donde los defectos se esconden mejor: registros y marcas de tiempo.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    Escribir puertas que realmente puedan fallar, y las primitivas de shell que las sostienen.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    Aprovechar bien una ventana de contexto, sobrevivir a la compactación, y no afirmar lo que no verificaste.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    La última milla: qué entra en una respuesta, cómo se cita, y cómo detectar texto que dejó de funcionar.

## Instalar en un agente concreto

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # ver los 84 identificadores
./install.sh --update            # traer la versión más reciente
```

## Nota sobre las habilidades

Las habilidades están en inglés a propósito, y esta es la razón: el agente
selecciona una habilidad leyendo su `name` y su `description`, y mantener esos
campos idénticos en todos los idiomas es lo que permite que la colección sea
enrutable independientemente del idioma en que escribas. Lo que sí está
traducido es todo lo que un lector necesita: el marco, la instalación, y qué hay
dentro de cada dominio.

Índice de traducciones y matriz de plataformas:
[`docs/i18n/README.md`](README.md) y [`docs/platforms.md`](../platforms.md).