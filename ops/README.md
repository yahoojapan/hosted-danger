# 運用
デプロイ・実行・更新には**Kubernetes**を利用

## リリース手順
- masterコミット時にScrewdriver.cdからcd.docker-registryに最新イメージをアップロードする
- イメージがアップロードされたら、Kubernetesのmasterにsshしてデプロイを実行

## master・node一覧
WIP

## master・node構築手順(共通)
対象のインスタンスをYNW(YJLinux 7系)で作成後、sshして以下のコマンドを実行
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/setup | sudo bash -s
```

## masterの構築手順
masterの冗長化のために、Externalなetcdをセットアップする
```bash
sudo yum install etcd -y
```

その後、`/etc/etcd/etcd.conf`の`ETCD_LISTEN_CLIENT_URLS`と`ETCD_ADVERTISE_CLIENT_URLS`をlocalhostから0.0.0.0に変更

etcdを起動
```bash
sudo service etcd start
```

[ops/kube/master.yaml](https://ghe.corp.yahoo.co.jp/approduce/hosted-danger/blob/master/ops/kube/master.yaml)の`endpoints`と`apiServerCertSANs`に対象masterのipアドレスを追加しておく

他のmasterから`/etc/kubernetes/pki`をscpなどを使いコピーしてくる
やり方はなんでも良いが、例としては以下のような手順 (172.21.232.27はmaster 1のIP)
```
[master 1] sudo cp -r /etc/kubernetes/pki ~/.
[master 1] sudo chown -R taicsuzu:users pki
[master 2] scp -r 172.21.232.27:/home/taicsuzu/pki .
[master 2] sudo mv pki /etc/kubernetes/.
[master 2] sudo chown -R root:root /etc/kubernetes/pki
```

kubeadmの初期化
```bash
wget https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/master.yaml && \
  sudo kubeadm init --config master.yaml
```

設定ファイルを手元にコピー(**master構築者以外の人も操作するには実行が必要**)
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

ネットワークのセットアップ
```bash
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/service.yaml
```

## nodeの追加手順
どこかのmasterで以下のコマンドを実行し、結果を控える
```bash
sudo kubeadm token create --print-join-command
```

対象のnodeにsshし、上のコマンドをsudo付きで実行
```bash
sudo kubeadm join --token ...
```

masterにsshして以下のコマンドを実行し、認識されていれば成功
```bash
kubectl get nodes
```

nodeというラベルを付与する(masterで実行)
```bash
kubectl label node [対象nodeのホスト名] node-role.kubernetes.io/node=
```

## リリース・デプロイ手順
masterにマージされた時点で、[cd.docker-registry](http://cd.docker-registry.corp.yahoo.co.jp/repository/approduce/hosted-danger-image)にイメージがアップロードされる (この時点では未リリース)

その後、[ops/kube/deployment.yaml](https://ghe.corp.yahoo.co.jp/approduce/hosted-danger/blob/master/ops/kube/deployment.yaml#L17)のイメージのタグを[cd.docker-registry](http://cd.docker-registry.corp.yahoo.co.jp/repository/approduce/hosted-danger-image)を参考に最新のものに書き換え、masterにマージする

リリースする場合はmasterにsshして以下を実行する
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/approduce/hosted-danger/master/ops/kube/deployment.yaml
```

`deployment "hd-deployment" configured`というメッセージが出たら成功、`unchanged`だとイメージタグが変更されていない

`kubectl get pods`などを実行し、Podが一定数`Running`の状態かつ`ContainerCreating`のものがあれば正常にリリースが進行中

## Tips

### Dashboardの作成

全ての操作はmasterで行う

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

## トラブルシューティング

### PodからDNSの名前解決ができない
kubeletとdockerをリスタートしたら直った
```bash
sudo service kubelet restart
sudo service docker restart
```

### 以下のようなエラーが出て実行できない
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
master構築手順の"設定ファイルを手元にコピー"の手順が抜けている可能性大

### `kubectl get nodes`のSTATUSのNotReadyから変わらない
ネットワーク設定がデプロイされるまで時間がかかるため、基本待機
