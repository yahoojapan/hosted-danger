require "uri"
require "json"
require "../executor/*"

module HostedDanger
  class ExecOpenPr
    include Github
    include Parser
    def initialize
      @web_hook = WebHook.new
    end

    def exec(context, params)
      git_url = context.request.body
      return context unless !git_url.nil?
      string_url = git_url.gets
      return context if string_url.nil?
      arr = string_url.split("/")
      git_host = arr[2]
      org = arr[3]
      repo = arr[4]
      access_token = access_token_from_git_host(git_host)
      json = pull_requests(git_host, org, repo, access_token)
      size = json.size-1
      (0..size).each do |num|
        executables = e_pull_request(json, num)
        executables.each do |executable|
          executor = Executor.new(executable)
          executor.exec_danger
        end
      end
      
      context.response.status_code = 200
      context
    end

    def e_pull_request(payload_json, num) : Array(Executable)?
      action = "synchronize"
      html_url = payload_json[num]["head"]["repo"]["html_url"].as_s
      pr_number = payload_json[num]["number"].as_i
      sha = payload_json[num]["head"]["sha"].as_s
      head_label = payload_json[num]["head"]["label"].as_s
      base_label = payload_json[num]["base"]["label"].as_s
      env = {} of String => String
      event = "pull_request"

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        head_label:  head_label,
        base_label:  base_label,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

  end
end
