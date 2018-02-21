require "json"

module HostedDanger
  class WebHook
    def initialize
    end

    def hook(context, params)
      payload : String = if body = context.request.body
        body.gets_to_end
      else
        raise "Empty body"
      end

      payload_json = JSON.parse(payload)

      executables? = create_executable(context, payload_json)

      if executables = executables?
        executables.each { |executable| exec_danger(executable) }
      end

      context.response.status_code = 200
      context.response.print "OK"
      context
    rescue e : Exception
      L.error e.message.not_nil!

      context.response.status_code = 400
      context.response.print "Bad Request"
      context
    end

    def create_executable(context, payload_json) : Array(Executable)?
      event = context.request.headers["X-GitHub-Event"]

      return e_pull_request(payload_json) if event == "pull_request"
      return e_pull_request_review(payload_json) if event == "pull_request_review"
      return e_issue_comment(payload_json) if event == "issue_comment"
      return e_status(payload_json) if event == "status"

      L.info "danger will not be triggered (#{event})"
    end

    def e_pull_request(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: closed" if payload_json["action"] == "closed"

      action = payload_json["action"].as_s
      event = "pull_request"
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["number"].as_i

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        raw_payload: payload_json.to_s,
      }]
    end

    def e_pull_request_review(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: dismissed" if payload_json["action"] == "dismissed"

      action = payload_json["action"].as_s
      event = "pull_request_review"
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["pull_request"]["number"].as_i

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        raw_payload: payload_json.to_s,
      }]
    end

    def e_issue_comment(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: deleted" if payload_json["action"] == "deleted"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        ENV["DANGER_PR_COMMENT"] = payload_json["comment"]["body"].as_s

        action = payload_json["action"].as_s
        event = "issue_comment"
        html_url = $1.to_s
        pr_number = $2.to_i

        return [{
          action:      action,
          event:       event,
          html_url:    html_url,
          pr_number:   pr_number,
          raw_payload: payload_json.to_s,
        }]
      end

      nil
    end

    def e_status(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"

      action = payload_json["state"].as_s
      event = "status"
      html_url = payload_json["repository"]["html_url"].as_s
      git_host = git_host_from_html_url(html_url)
      access_token = access_token_from_git_host(git_host)

      commit_sha = payload_json["sha"].as_s
      org, repo = org_repo_from_html_url(html_url)

      pulls_json = open_pulls_from_sha(git_host, org, repo, access_token, commit_sha)

      executables = [] of Executable

      pulls_json.each do |pull_json|
        executables << {
          action:      action,
          event:       event,
          html_url:    html_url,
          pr_number:   pull_json["number"].as_i,
          raw_payload: payload_json.to_s,
        } if pull_json["head"]["sha"].as_s == commit_sha
      end

      executables
    end

    include Executor
  end
end
