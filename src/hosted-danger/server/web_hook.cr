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
      message : String = if message = e.message
                           message
                         else
                           "No message"
                         end

      paster_url = if _payload = payload
                     upload_text(_payload)
                   else
                     "No payload"
                   end

      L.error "message:\n\n#{message}\n\nlog\n\n#{paster_url}"

      context.response.status_code = 400
      context.response.print "Bad Request"
      context
    end

    def create_executable(context, payload_json) : Array(Executable)?
      event = context.request.headers["X-GitHub-Event"]

      return e_pull_request(payload_json) if event == "pull_request"
      return e_pull_request_review(payload_json) if event == "pull_request_review"
      return e_pull_request_review_comment(payload_json) if event == "pull_request_review_comment"
      return e_issue_comment(payload_json) if event == "issue_comment"
      return e_status(payload_json) if event == "status"

      L.info "danger will not be triggered (#{event})"
    end

    def e_pull_request(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "skip: closed" if payload_json["action"] == "closed"

      action = payload_json["action"].as_s
      event = "pull_request"
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_pull_request_review(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "skip: dismissed" if payload_json["action"] == "dismissed"

      action = payload_json["action"].as_s
      event = "pull_request_review"
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["pull_request"]["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_pull_request_review_comment(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "skip: deleted" if payload_json["action"] == "deleted"

      action = payload_json["action"].as_s
      event = "pull_request_review_comment"
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["pull_request"]["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_issue_comment(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "skip: deleted" if payload_json["action"] == "deleted"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        action = payload_json["action"].as_s
        event = "issue_comment"
        html_url = $1.to_s
        pr_number = $2.to_i

        env = {} of String => String
        env["DANGER_PR_COMMENT"] = payload_json["comment"]["body"].as_s

        git_host = git_host_from_html_url(html_url)
        access_token = access_token_from_git_host(git_host)
        org, repo = org_repo_from_html_url(html_url)

        pull_json = pull_request(git_host, org, repo, pr_number, access_token)

        return [{
          action:      action,
          event:       event,
          html_url:    html_url,
          pr_number:   pr_number,
          sha:         pull_json["head"]["sha"].as_s,
          raw_payload: payload_json.to_json,
          env:         env,
        }]
      end

      nil
    end

    def e_status(payload_json) : Array(Executable)?
      return L.info "skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"

      action = payload_json["state"].as_s
      event = "status"
      html_url = payload_json["repository"]["html_url"].as_s
      git_host = git_host_from_html_url(html_url)
      access_token = access_token_from_git_host(git_host)
      env = {} of String => String

      sha = payload_json["sha"].as_s
      org, repo = org_repo_from_html_url(html_url)

      pulls_json = pull_requests(git_host, org, repo, access_token)

      executables = [] of Executable

      pulls_json.each do |pull_json|
        executables << {
          action:      action,
          event:       event,
          html_url:    html_url,
          pr_number:   pull_json["number"].as_i,
          sha:         sha,
          raw_payload: payload_json.to_json,
          env:         env,
        } if pull_json["head"]["sha"].as_s == sha
      end

      executables
    end

    include Executor
  end
end
