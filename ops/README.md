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

kubectlをroot以外で実行できるようにコピーしておく(オプショナル、やらない場合はsudo付きで実行)
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

kubeadmをセットアップ
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

[Calico](https://docs.projectcalico.org/v2.0/getting-started/kubernetes/)を使用しLBをセットアップ
```
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
```

podのデプロイとserviceを使用した外部公開
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/deployment.yaml
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/service.yaml
```

以下のコマンドを実行し、控えておく(nodeがmasterに参加する際に必要)
```bash
sudo kubeadm token create --print-join-command
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

## リリース・デプロイ手順
masterにマージされた時点で、[cd.docker-registry](http://cd.docker-registry.corp.yahoo.co.jp/repository/approduce/hosted-danger-image)にイメージがアップロードされる (この時点では未リリース)

その後、[ops/kube/deployment.yaml](https://ghe.corp.yahoo.co.jp/approduce/hosted-danger/blob/master/ops/kube/deployment.yaml#L17)のイメージのタグを[cd.docker-registry](http://cd.docker-registry.corp.yahoo.co.jp/repository/approduce/hosted-danger-image)を参考に最新のものに書き換え、masterにマージする

リリースする場合はmasterにsshして以下を実行する
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/deployment.yaml
```

`deployment "hd-deployment" configured`というメッセージが出たら成功、`unchanged`だとイメージタグが変更されていない

`kubectl get pods`などを実行し、Podが一定数`Running`の状態かつ`ContainerCreating`のものがあれば正常にリリースされている

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

### PodからDNSの名前解決ができない
kubeletとdockerをリスタートしたら直った
```bash
sudo service kubelet restart
sudo service docker restart
```
