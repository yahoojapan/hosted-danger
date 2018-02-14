# 運用
デプロイ・実行・更新には**Kubernetes**を利用

## リリース手順
- masterコミット時にScrewdriver.cdからcd.docker-registryに最新イメージをアップロードする
- イメージがアップロードされたら、Kubernetesのmasterにsshしてデプロイを実行

## master・node一覧
WIP

## masterの構築手順
対象のインスタンスをYNW(YJLinux 7系)で作成後、sshして以下のコマンドを実行
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/node | sudo bash -s
```

**最後に出力される以下のコマンドは必ず控える**
```bash
kubeadm join --token...
```

root以外で実行できるようにコピーしておく
```bash
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

podのデプロイとserviceを使用した外部公開
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/deployment.yaml
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/service.yaml
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

## Tips

### Dashboardの作成

全ての操作はmasterで行う

Dashboardの作成
```bash
https://github.com/kubernetes/dashboard/wiki/Installation
```

外部接続できるように設定を変更
```bash
kubectl edit service kubernetes-dashboard -n kube-system 
```
＊) vimが開くので、`ClusterIP`を`NodePort`に変更

以下を実行し、実行portを確認(3xxxx番台くらいのもの)
```bash
kubectl get service kubernetes-dashboard -n kube-system
```

この時点で http**s**://[masterのホスト]:[上のport]/ にログインできることを確認する

次にサービスアカウントを作成
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/admin-user.yaml
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/admin-user-role.yaml
```

ログインに必要なTokenの取得
```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

あとはDashboardにアクセスし、取得したTokenでログインする

参考1: [Dashboardの作成](https://github.com/kubernetes/dashboard/wiki/Installation)
参考2: [Dashboardの外部接続](https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above#nodeport)
参考3: [Service Accountの作成](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)
