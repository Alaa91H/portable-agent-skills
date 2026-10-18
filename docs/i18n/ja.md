# Essential Agent Skills — 日本語

<!-- i18n: lang=ja clusters=18 skills=79 -->

ソフトウェア開発の全工程を覆う、**検証済みのエージェントスキル 79 個**の
コレクションです。何を作るかを決め、テストファーストで実装し、レビューを受け、
リリースし、運用し、そして自前のスキルを書くことまでを対象にします。

各スキルはオープンな
[Agent Skills 仕様](https://agentskills.io/specification)に準拠し、この
リポジトリ内のバリデータが検査します。すべてのエージェント探索規則にミラー
されているため、設定なしでどのエージェントとも連携できます。

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

## 含まれるもの

| | |
| --- | --- |
| スキル | 79 個、18 の領域 |
| エージェント | 検証済みのインストール先 14 件 |
| 形式 | 素の Markdown、依存なし |
| ライセンス | MIT |

## 領域一覧

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   何をするかを決め、テストファーストで実装し、それが動作することを証明する。
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   レビューを受け、指摘に対応し、負荷の下で実証する。
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   状況を掴み、動かし、最新に保ち、構造を扱える状態に保つ。
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   ブランチ、worktree、マージ、そして git が想定外の動きをしたときの内側の仕組み。
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   インターフェースの構築とレビュー。ローカライズと WCAG 適合を含む。
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   HTTP と GraphQL の契約、バージョニング、webhook、認証、決済。
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   クエリ、スキーマ変更、キャッシュ、バックグラウンド処理。
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   ウェアハウスのモデリング、パイプラインの編成、分散計算の調整。
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   コンテナ、オーケストレーション、インフラコード、CI パイプライン、ホスト、インシデント。
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    クラウドの姿勢とコスト、シークレットとフラグ、検索の関連性、モバイル公開。
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    ボトルネックを特定し、並行性を論じ、システムが健全かを知る。
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    リリース、復旧、スケジューリング、そして人物に関するデータの取り扱い。
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    コード、依存関係、レスポンスヘッダ、エージェント入力の悪用可能な欠陥を見つける。
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    言語モデル上に構築し、エージェントスキルの記述・提供・配布を行う。
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    欠陥が最も隠れやすい領域:ログとタイムスタンプ。
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    本当に失敗しうるゲートと、その下にある shell プリミティブを書く。
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    コンテキスト窓をうまく使い、圧縮を経ても筋の通った議論を保ち、検証していないことを主張しない。
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    最後のひと区切り:答えに入るもの、その出典、そして壊れた文章の見つけ方。

## 特定のエージェントに導入する

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # 79 個の識別子を表示
./install.sh --update            # 最新版を取得
```

## スキルが英語である理由

エージェントは `name` と `description` を読んでスキルを選びます。この 2 つの
フィールドを全言語で同一に保つことが、質問の言語にかかわらずコレクションを
正しくルーティングできるようにする要点です。翻訳されているのは読み手が実際に
必要とする部分、つまり位置づけ、導入手順、各領域の内容です。

翻訳索引とプラットフォーム対応表:
[`docs/i18n/README.md`](README.md) と [`docs/platforms.md`](../platforms.md)。