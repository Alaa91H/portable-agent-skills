# Essential Agent Skills — Português (Brasil)

<!-- i18n: lang=pt-BR clusters=18 skills=83 -->

Uma coleção curada e validada de **83 habilidades para agentes**, cobrindo todo o
ciclo do trabalho de software: decidir o que construir, construir com testes
primeiro, passar por revisão, publicar, operar — e escrever habilidades próprias.

Cada habilidade segue a especificação aberta
[Agent Skills](https://agentskills.io/specification), verificada por um validador
deste repositório e espelhada em cada convenção de descoberta de agentes, para
funcionar com qualquer agente sem configuração.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## O que está incluído

| | |
| --- | --- |
| Habilidades | 83, em 18 domínios |
| Agentes | 14 destinos de instalação verificados |
| Formato | Markdown puro, sem dependências |
| Licença | MIT |

## Os domínios

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   Decidir o que fazer, fazer com testes primeiro e provar que funciona.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   Submeter o trabalho a revisão, agir sobre o retorno e provar sob carga.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   Orientar-se, colocar de pé, manter atualizado e manter a estrutura viável.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   Branches, worktrees, merges e a canalização interna quando o git surpreende.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   Construir e revisar interfaces, incluindo localização e conformidade WCAG.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   Contratos HTTP e GraphQL, versionamento, webhooks, autenticação e pagamentos.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   Consultas, mudanças de esquema, cache e processamento em segundo plano.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   Modelar o warehouse, orquestrar pipelines e ajustar computação distribuída.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   Contêineres, orquestração, código de infraestrutura, esteiras de CI, hosts e incidentes.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    Postura e custo na nuvem, segredos e flags, relevância de busca e publicação mobile.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    Achar o gargalo, raciocinar sobre concorrência e saber se o sistema está saudável.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    Publicar, recuperar, agendar e tratar os dados que você guarda sobre pessoas.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    Encontrar falhas exploráveis em código, dependências, cabeçalhos e entradas de agente.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    Construir sobre modelos de linguagem, e escrever, servir e distribuir habilidades.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    Os domínios onde os defeitos se escondem melhor: logs e carimbos de tempo.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    Escrever guardas que realmente podem falhar, e as primitivas de shell por baixo.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    Usar bem uma janela de contexto, sobreviver à compactação e não afirmar o que não verificou.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    A última milha: o que entra numa resposta, como é fundamentada, e como perceber texto quebrado.

## Instalar para um agente específico

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # ver os 83 identificadores
./install.sh --update            # trazer a versão mais recente
```

## Por que as habilidades continuam em inglês

O agente escolhe uma habilidade lendo o `name` e a `description` dela. Manter
esses campos idênticos em todos os idiomas é o que torna a coleção roteável
independentemente da língua da sua pergunta. O que foi traduzido é tudo o que um
leitor precisa: o enquadramento, a instalação e o conteúdo de cada domínio.

Índice de traduções e matriz de plataformas:
[`docs/i18n/README.md`](README.md) e [`docs/platforms.md`](../platforms.md).