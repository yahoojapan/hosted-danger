# 運用

デプロイ・実行・更新には**Kubernetes**を利用

## リリース手順
- masterコミット時にScrewdriver.cdからcd.docker-registryに最新イメージをアップロードする
- イメージがアップロードされたら、Kubernetesのmasterにsshしてデプロイを実行

## master・node一覧
WIP

## masterの追加手順
対象のインスタンスをYNW(YJLinux 7系)で作成後、sshして以下のコマンドを実行
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/node | sudo bash -s
```

**最後に出力される以下のコマンドは必ず控える**
```bash
kubeadm join --token...
```

## nodeの追加手順
対象のインスタンスをYNW(YJLinux 7系)で作成後、sshして以下のコマンドを実行
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/node | sudo bash -s
```

**実行後にmasterで出力されたコマンドを実行する(sudoで実行する)**
```bash
sudo kubeadm join --token...
```

masterにsshして以下のコマンドを実行し、認識されていれば成功
```bash
kubectl get nodes
```

nodeというラベルを付与する(masterで実行)
```bash
kubectl label node [nodeのホスト名] node-role.kubernetes.io/node=

# 例
kubectl label node hd-node-002.ssk.ynwm.yahoo.co.jp node-role.kubernetes.io/node=
```
