# Quick start

## Launch Hosted Danger

These are quired to start Hosted Danger
- At least an instance is needed which can communicate with your Github environment in TCP.
- Docker environment in the instance.
- An access token of yours with repo scope. You can create it in your github settings page. (Settings => Developer settings => Personal access tokens)

In the below example, it's assumed that you are using github.com.

Pull a Hosted Danger's docker image from hub.docker.com.
```bash
TBD
```

Create a configuration file at somewhere. It looks like this.
```yaml
githubs:
  - host: github.com
    env: ACCESS_TOKEN
    symbol: git
    api_base: https://api.github.com
    raw_base: https://raw.githubusercontent.com
```

|          | Description                            | Examples                                                                                  |
|----------|----------------------------------------|-------------------------------------------------------------------------------------------|
| host     | Host of github you use.                | github.com                                                                                |
| env      | Name of env var to store access token. | ACCESS_TOKEN                                                                              |
| symbol   | Unique symbol for each github.         | git                                                                                       |
| api_base | Base url of github API.                | https://api.github.com, https://yourgithub.com/api/v3                                     |
| raw_base | Base url to the raw files on github.   | https://raw.githubusercontent.com, https://raw.yourgithub.com, https://yourgithub.com/raw |

Now you can launch the server like this.
```bash
docker run -d \
     -e ACCESS_TOKEN=[Your access token] \
     -p 80:80 -v [Path to the]/config.yaml:/opt/hd/config.yaml --name hosted-danger-container hosted-danger
```

If you see the logs like this, it successfully launched.
```bash
> docker logs -f hosted-danger-container

[2018-10-05 04:36:20]: [Info] Start listening on 0.0.0.0:80
```

## Setting Webhook

Add webhook to the target repository.
Go the repository's Settings page, select Webhooks tab and add webhook as below.

| Payload URL                                          | http(s)://your_hosted_danger_instance.com/hook |
|------------------------------------------------------|------------------------------------------------|
| Content type                                         | application/json                               |
| Secret                                               | None                                           |
| Which events would you like to trigger this webhook? | Send me everything.                            |
| Active                                               | On (Active)                                    |


