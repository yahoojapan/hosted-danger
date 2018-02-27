# 運用
デプロイ・実行・更新には**Kubernetes**を利用

## リリース・デプロイ手順
masterにマージされた時点で、本番環境へのリリースが完了する。

詳しくは[screwdriver.yaml](https://ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/blob/master/screwdriver.yaml)を参照。

## master・node構築手順(共通)
対象のインスタンスをYNW(YJLinux 7系)で作成後、sshして以下のコマンドを実行
```bash
curl -sf https://raw.ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/master/ops/setup | sudo bash -s
```

## masterの構築手順
kubeadmの初期化
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
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
```

Serviceを80番ポートで立ち上げるため、`/etc/kubernetes/manifests/kube-apiserver.yaml`のspec.containers.commandに以下のオプションを追加
```bash
--service-node-port-range=80-32767
```

kubeletをリスタート
```bash
sudo service kubelet restart
```

Serviceの立ち上げ
```bash
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/master/ops/kube/service.yaml
```

## nodeの追加手順
masterで以下のコマンドを実行し、結果を控える
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

## Tips

## 手元からkubectlを実行する

1. 手元にkubectlをインストールする
```bash
brew install kubectl
```

2. `hosted-danger/hosted-danger-secrets`からconfigをDLしてきて、手元の`.kube/config`をそれに置き換える

## Podのログを見る

以下でも良いが、
```bash
kubectl logs [pod名] -f
```

[stern](https://github.com/wercker/stern)が楽でおすすめ
```bash
brew install stern
stern hd-deployment*
```

### PVM等でリブートが必要になったの方法

masterは特に何も気にせずrebootしてしまってOK

nodeは以下の手順が必要

1. masterにてrebootするnode名を確認
```bash
kubectl get nodes
```

2. masterから対象のnodeをdrainする ([Safely Drain a Node while Respecting Application SLOs](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node))
```bash
kubectl drain [node名] --ignore-daemonsets --delete-local-data
```

3. drainが完了したら以下のコマンドで対象nodeにPodが存在しないことを確認
```bash
kubectl get pods -o wide
```

4. nodeにログインしてreboot

5. masterにて、一旦対象nodeをdeleteする
```bash
kubectl delete node kube-n-a-002.ssk.ynwm.yahoo.co.jp
```

6. 対象nodeにログインして、再びmasterにjoinする
```bash
sudo kubeadm reset
sudo kubeadm join --token [token] 172.21.232.27:6443 --discovery-token-ca-cert-hash sha256:[sha256]
```

＊) `sudo kubeadm join...`のコマンドは、node追加手順に取得方法の記載あり

### Dashboardの作成

全ての操作はmasterで行う

下記を実行
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
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
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/master/ops/kube/admin-user.yaml
kubectl apply -f https://raw.ghe.corp.yahoo.co.jp/hosted-danger/hosted-danger/master/ops/kube/admin-user-role.yamlg
```

ログインに必要なTokenの取得
```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

あとはDashboardにアクセスし、取得したTokenでログインする

- 参考1: [Dashboardの作成](https://github.com/kubernetes/dashboard/wiki/Installation)
- 参考2: [Dashboardの外部接続](https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above#nodeport)
- 参考3: [Service Accountの作成](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)

## トラブルシューティング

### PodからDNSの名前解決ができない
-> kubeletとdockerをリスタートしたら直った
```bash
sudo service kubelet restart
sudo service docker restart
```

### `kubectl get nodes`のSTATUSがNotReadyから変わらない
-> ネットワーク設定がデプロイされるまで時間がかかるため、基本待機

### 以下のようなエラーが出て`kubectl get nodes`などが実行できない
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
-> master構築手順の"設定ファイルを手元にコピー"の手順が抜けている可能性大

### 以下のようなエラーが出てservice.yamlの適応に失敗
```
The Service "hd-service" is invalid: spec.ports[0].nodePort: Invalid value: 80: provided port is not in the valid range. The range of valid ports is 30000-32767
```
-> `/etc/kubernetes/manifests/kube-apiserver.yaml`の変更漏れ
