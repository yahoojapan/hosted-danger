require "uri"
require "json"
require "../executor/*"

module HostedDanger
  class ExecOpenPr
    def initialize
      @web_hook = WebHook.new
    end

    def exec(context, params)
      git_repo_url = context.request.body.try &.gets_to_end
      return context unless !git_repo_url.nil?
      git_host = URI.parse(git_repo_url).host
      org = org_repo_from_html_url(git_repo_url)[0]
      repo = org_repo_from_html_url(git_repo_url)[1]
      return context unless !git_host.nil?
      access_token = access_token_from_git_host(git_host)
      payload_jsons = pull_requests(git_host, org, repo, access_token).as_a
      payload_jsons.each do |payload_json|
        executable = e_pull_request(payload_json)
        executor = Executor.new(executable)
        executor.exec_danger
      end
      
      context.response.status_code = 200
      context
    end

    def e_pull_request(payload_json)
      action = "synchronize"
      html_url = payload_json["head"]["repo"]["html_url"].as_s
      pr_number = payload_json["number"].as_i
      sha = payload_json["head"]["sha"].as_s
      head_label = payload_json["head"]["label"].as_s
      base_label = payload_json["base"]["label"].as_s
      env = {} of String => String
      event = "status"

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
    end

    include Github
    include Parser
  end
end
