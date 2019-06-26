module HostedDanger
  class ExecOpenPr
    def initialize
      @web_hook = WebHook.new
      @channel = Channel(Array(Executable)).new
    end

    def exec(context, params)
      json_payload = @web_hook.create_payload_json(context)
      git_repo_url = json_payload["scm_url"].as_s
      git_host = git_host_from_html_url(git_repo_url)
      org, repo = org_repo_from_html_url(git_repo_url)
      access_token = access_token_from_git_host(git_host)

      executables = Array(Executable).new

      if repo == "danger"
        repos_json = all_repos(git_host, org, access_token)
        repos = create_repos(repos_json)

        spawn do
          repos.each do |repo|
            payload_jsons = pull_requests(git_host, org, repo, access_token)
            @channel.send(create_executables(payload_jsons))
          end
        end

        repos.each do
          executables.concat(@channel.receive)
        end
      else
        payload_jsons = pull_requests(git_host, org, repo, access_token)
        executables = create_executables(payload_jsons)
      end

      spawn do
        executables.each do |executable|
          executor = Executor.new(executable)
          executor.exec_danger
        end
      end

      context.response.status_code = 200
      context.response.print "ok"
      context
    rescue e : Exception
      L.error e, e.message

      @web_hook.bad_request(context)
    end

    def create_executables(payload_jsons)
      payload_jsons.map { |payload_json|
        action = "build_periodcally"
        html_url = payload_json["head"]["repo"]["html_url"].as_s
        pr_number = payload_json["number"].as_i
        sha = payload_json["head"]["sha"].as_s
        head_label = payload_json["head"]["label"].as_s
        base_label = payload_json["base"]["label"].as_s
        env = {} of String => String
        event = "build_periodcally"

        {
          action:      action,
          event:       event,
          html_url:    html_url,
          pr_number:   pr_number,
          sha:         sha,
          head_label:  head_label,
          base_label:  base_label,
          raw_payload: payload_json.to_json,
          env:         env,
        }
      }
    end

    def create_repos(repo_jsons)
      repo_jsons.map { |repo_json| repo = repo_json["name"].as_s }
    end

    include Github
    include Parser
  end
end
