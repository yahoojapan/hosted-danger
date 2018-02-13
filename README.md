# Hosted Danger

Dangerの実行をホスティングするプラットフォーム

## 必要な環境
- crystal

以下の設定を.gitに導入(format用)
```bash
cp tools/pre-commit .git/hooks/.
```

## ビルド
```bash
shards build
```

## テスト
```bash
crystal spec
```

## Dockerを使用した実行

### 必要な環境
- docker
- [docker-clean](https://github.com/ZZROTDesign/docker-clean)

### コマンド
```bash
# ビルド
> sudo ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make build

# コンテナの停止 & 削除
> sudo make stop

# デーモンとしてコンテナを起動
> sudo make run

# インタラクティブにコンテナを起動(デバッグ用途)
> sudo make run-i

# デーモンとしてコンテナをリスタート (ビルド -> 停止 -> 削除 -> スタート)
> sudo ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun

# インタラクティブにコンテナをリスタート (ビルド -> 停止 -> 削除 -> スタート)
> sudo ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun-i
```

*) Dragon関係の環境変数は [BundlerCache](https://ghe.corp.yahoo.co.jp/approduce/BundlerCache) に使用しています、BundlerCacheは使用できませんがなくても動きます.

## 仕様・開発・運用

### Bundlerの使用について
- Gemfileが存在し、dangerが定義されている場合はbundlerを使用する
- Gemfileが存在し、dangerが定義されていない場合はbundlerを使用しない
- Gemfileが存在しない場合は、bundlerを使用しない

### デフォルトのDangerfileの内容を変更する
Dangerfile.defaultを編集

### デフォルトで導入されているプラグインを追加したい
GemfileとGemfile.lockの編集

### リリース手順
WIP

### Screwdriver.cdで使用しているイメージ
- [hosted-danger-sd-image](https://ghe.corp.yahoo.co.jp/approduce/hosted-danger-sd-image)
