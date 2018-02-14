# 運用

デプロイ・実行・更新にはKubernetesを利用

## nodeの追加手順

masterのIPアドレスと追加するnodeのIPアドレス`ifconfig`などで調べて、追加するnode内で以下のコマンドを実行

```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/node | \
    sudo MASTER_IP=<masterのIPアドレス> NODE_IP=<追加するnodeのIPアドレス> bash -s
```

masterにsshして以下のコマンドを実行し、認識されていれば成功
```bash
kubectl get nodes
```
