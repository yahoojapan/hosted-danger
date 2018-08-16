require "uri"
require "json"
require "../executor/*"
require "./web_hook"

module HostedDanger
  class ExecOpenPr
    def initialize
      @web_hook = WebHook.new
    end

    def exec(context, params)
      json_payload = @web_hook.create_payload_json(context)
      git_repo_url = json_payload["scm_url"].as_s
      git_host = git_host_from_html_url(git_repo_url)
      org, repo = org_repo_from_html_url(git_repo_url)
      access_token = access_token_from_git_host(git_host)

      payload_jsons = pull_requests(git_host, org, repo, access_token).as_a
      executables = create_executables(payload_jsons)
      executables.each do |executable|
        executor = Executor.new(executable)
        executor.exec_danger
      end
      
      context.response.status_code = 200
      context.response.print "ok"
      context
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
        event = "exec_openpr"

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

    include Github
    include Parser
  end
end
