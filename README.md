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

## Dockerを使用した手元での実行 (webhookの動作検証が含まれるのでynwm推奨)

### 必要な環境
- docker
- [docker-clean](https://github.com/ZZROTDesign/docker-clean)

ynw (YJLinux 7系) の場合、以下のコマンドでdockerとdocker-cleanをインストール可能
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/master/tools/setup | sudo bash -s
```

### コマンド
```bash
# ビルド
> sudo ACCESS_TOKEN_GHE=hoge ACCESS_TOKEN_PARTNER=hoga DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make build

# コンテナの停止 & 削除
> sudo make stop

# デーモンとしてコンテナを起動
> sudo make run

# インタラクティブにコンテナを起動(デバッグ用途)
> sudo make run-i

# デーモンとしてコンテナをリスタート (ビルド -> 停止 -> 削除 -> スタート)
> sudo ACCESS_TOKEN_GHE=hoge ACCESS_TOKEN_PARTNER=hoga DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun

# インタラクティブにコンテナをリスタート (ビルド -> 停止 -> 削除 -> スタート)
> sudo ACCESS_TOKEN_GHE=hoge ACCESS_TOKEN_PARTNER=hoga DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun-i
```

＊) `ACCESS_TOKEN_GHE`と`ACCESS_TOKEN_PARTNER`はそれぞれghe.corpとpartner.git.corpのAccess Token(要repoスコープ)
＊) Dragon関係の環境変数は [BundlerCache](https://ghe.corp.yahoo.co.jp/approduce/BundlerCache) に使用しています。

## 仕様・開発

### デフォルトのDangerfileの内容を変更したい
Dangerfile.defaultを編集

### デフォルトで導入されているプラグインを追加したい
GemfileとGemfile.lockの編集

### 内部実行でのBundlerの使用について
- Gemfileが存在し、dangerが定義されている場合はbundlerを使用する
- Gemfileが存在し、dangerが定義されていない場合はbundlerを使用しない
- Gemfileが存在しない場合は、bundlerを使用しない

## 運用
- Kubernetesのセットアップ及びリリース・デプロイなどの手順については[ops](https://ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/tree/master/ops)
- [Screwdriver.cdで使用しているイメージ(hosted-danger-sd-image)](http://cd.docker-registry.corp.yahoo.co.jp/repository/hosted-danger/hosted-danger-sd-image)
- [KubernetesのPodで使用しているイメージ(hosted-danger-image)](http://cd.docker-registry.corp.yahoo.co.jp/repository/hosted-danger/hosted-danger-image)
