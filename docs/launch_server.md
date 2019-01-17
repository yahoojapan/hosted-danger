# Launch Server

These are required to start Hosted Danger.
- At least an instance (server) is needed which can communicate with your Github in TCP.
  - Docker environment in it.
- Application account on Github.
  - Create an account for Hosted Danger. You **cannot** reuse your main account for it.
- An access token of the application account with repo scope.
  - Create it in your github settings page. (Settings => Developer settings => Personal access tokens)

In the following example, it's assumed that you are using github.com.

In the instance, build a Hosted Danger's docker image.
```bash
git clone https://github.com/yahoojapan/hosted-danger
cd hosted-danger && docker build -t hosted-danger .
```

Create a configuration file and save it as config.yaml. It looks like this.
Please rewrite the `[your_app_account_name]` part.
```yaml
githubs:
  - host: github.com
    user: your_app_account_name
    env: ACCESS_TOKEN
    symbol: github
    api_base: https://api.github.com
    raw_base: https://raw.githubusercontent.com
```

|          | Description                            | Examples                                                                                  |
|----------|----------------------------------------|-------------------------------------------------------------------------------------------|
| host     | Host of github you use.                | github.com                                                                                |
| user     | Username of your application account.  | your_app_account_name                                                                     |
| env      | Name of env var to store access token. | ACCESS_TOKEN                                                                              |
| symbol   | Unique symbol for each github.         | git                                                                                       |
| api_base | Base url of github API.                | https://api.github.com, https://yourgithub.com/api/v3                                     |
| raw_base | Base url to the raw files on github.   | https://raw.githubusercontent.com, https://raw.yourgithub.com, https://yourgithub.com/raw |

Now you can launch the server.
```bash
docker run -d \
     -e ACCESS_TOKEN=[Your access token] \
     -p 80:80 -v [Path to the]/config.yaml:/opt/hd/config.yaml --name hosted-danger-container hosted-danger
```

If you could see the below log, it's successfully launched.
```bash
> docker logs -f hosted-danger-container

[2018-10-05 04:36:20]: [Info] Start listening on 0.0.0.0:80
```

## Next Step
- [Setup Repository](/docs/setup_repository.md)
