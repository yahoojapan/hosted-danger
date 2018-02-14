# 運用

デプロイ・実行・更新には**Kubernetes**を利用

## master・node一覧

master (apiserver・etcdも同居)
- hd-master-dev-001.ssk.ynwm.yahoo.co.jp (172.21.143.224)

node
- hd-dev-001.ssk.ynwm.yahoo.co.jp (172.21.149.10)
- hd-dev-002.ssk.ynwm.yahoo.co.jp (172.21.116.39)

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
