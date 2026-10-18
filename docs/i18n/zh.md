# Essential Agent Skills — 简体中文

<!-- i18n: lang=zh clusters=18 skills=83 -->

一套经过审校与验证的 **83 个 Agent 技能**，覆盖软件工作的完整链路：决定要做什么、
以测试先行方式实现、提交评审、发布、运行维护，以及编写自己的技能。

每个技能都遵循开放的
[Agent Skills 规范](https://agentskills.io/specification)，由本仓库中的校验器
强制检查，并镜像到各种 Agent 的发现路径，因此无需配置即可与任意 Agent 配合使用。

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## 包含内容

| | |
| --- | --- |
| 技能 | 83 个，覆盖 18 个领域 |
| Agent | 14 个已验证的安装目标 |
| 格式 | 纯 Markdown，无依赖 |
| 许可 | MIT |

## 领域一览

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   决定做什么、以测试先行实现、并证明它确实可用。
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   让工作接受评审、根据反馈行动、并在负载下加以验证。
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   熟悉项目、把它跑起来、保持与时俱进，并让结构保持可维护。
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   分支、worktree、合并，以及 git 出其不意时的底层机制。
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   构建与评审界面，包括本地化与 WCAG 合规。
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   HTTP 与 GraphQL 契约、版本管理、Webhook、认证与支付。
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   查询、表结构变更、缓存与后台处理。
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   建模数据仓库、编排流水线、调优分布式计算。
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   容器、编排、基础设施代码、CI 流水线、主机与故障处理。
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    云端态势与成本、密钥与开关、搜索相关性、移动端发布。
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    找出瓶颈、推理并发行为、判断系统是否健康。
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    发布、恢复、调度，以及处理你所持有的关于人的数据。
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    在代码、依赖、响应头与 Agent 输入中找出可被利用的缺陷。
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    基于语言模型构建，以及编写、提供与分发 Agent 技能。
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    最容易藏匿缺陷的领域：日志与时间戳。
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    编写真正可能失败的关卡，以及支撑它们的 shell 原语。
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    善用上下文窗口、在压缩后仍然连贯、绝不声称未经验证的事。
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    最后一公里：答案中放入什么、如何标注来源、如何发现已经损坏的文本。

## 安装到指定 Agent

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # 查看 83 个技能标识符
./install.sh --update            # 获取最新版本
```

## 关于技能语言

技能正文刻意保持英文：Agent 是通过 `name` 与 `description` 来选择技能的，
让这些字段在各语言中保持一致，正是使本合集无论提问语言为何都能被正确路由的
关键。已翻译的是读者真正需要的部分：整体说明、安装方式，以及每个领域涵盖什么。

翻译索引与平台矩阵：
[`docs/i18n/README.md`](README.md) 与 [`docs/platforms.md`](../platforms.md)。