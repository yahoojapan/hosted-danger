module HostedDanger
  class WebHook
    def hook(context, params)
      payload : String = if body = context.request.body
        body.gets_to_end
      else
        raise "Empty body"
      end

      payload_for_error_log = payload
      payload_json = JSON.parse(payload)

      executables? = create_executable(context, payload_json)

      if executables = executables?
        executables.each { |executable| exec_danger(executable) }
      end

      context.response.status_code = 200
      context.response.print "OK"
      context
    rescue e : Exception
      message : String = if error_message = e.message
        error_message
      else
        "No message"
      end

      backtrace : String = if _backtrace = e.backtrace?
                             _backtrace.join("\n")
                           else
                             "No backtrace"
                           end

      paster_url = if _payload_for_error_log = payload_for_error_log
                     upload_text(_payload_for_error_log)
                   else
                     "No payload"
                   end

      L.error "<< Message >>:\n#{message}\n\n<< Backtrace >>\n```\n#{backtrace}\n```\n\n<< Log >>\n#{paster_url}"

      context.response.status_code = 400
      context.response.print "Bad Request"
      context
    end

    def create_executable(context, payload_json) : Array(Executable)?
      event = context.request.headers["X-GitHub-Event"]

      return e_pull_request(event, payload_json) if event == "pull_request"
      return e_pull_request_review(event, payload_json) if event == "pull_request_review"
      return e_pull_request_review_comment(event, payload_json) if event == "pull_request_review_comment"
      return e_issue_comment(event, payload_json) if event == "issue_comment"
      return e_issues(event, payload_json) if event == "issues"
      return e_status(event, payload_json) if event == "status"

      L.info "danger will not be triggered (#{event})"
    end

    def e_pull_request(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "#{event} skip: closed" if payload_json["action"] == "closed"

      action = payload_json["action"].as_s
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      base_branch = payload_json["pull_request"]["base"]["ref"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        base_branch: base_branch,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_pull_request_review(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "#{event} skip: dismissed" if payload_json["action"] == "dismissed"

      action = payload_json["action"].as_s
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["pull_request"]["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      base_branch = payload_json["pull_request"]["base"]["ref"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        base_branch: base_branch,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_pull_request_review_comment(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "#{event} skip: deleted" if payload_json["action"] == "deleted"

      action = payload_json["action"].as_s
      html_url = payload_json["repository"]["html_url"].as_s
      pr_number = payload_json["pull_request"]["number"].as_i
      sha = payload_json["pull_request"]["head"]["sha"].as_s
      base_branch = payload_json["pull_request"]["base"]["ref"].as_s
      env = {} of String => String

      [{
        action:      action,
        event:       event,
        html_url:    html_url,
        pr_number:   pr_number,
        sha:         sha,
        base_branch: base_branch,
        raw_payload: payload_json.to_json,
        env:         env,
      }]
    end

    def e_issue_comment(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "#{event} skip: deleted" if payload_json["action"] == "deleted"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        action = payload_json["action"].as_s
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
          base_branch: pull_json["base"]["ref"].as_s,
          raw_payload: payload_json.to_json,
          env:         env,
        }]
      end

      nil
    end

    def e_issues(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"
      return L.info "#{event} skip: closed" if payload_json["action"] == "closed"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        action = payload_json["action"].as_s
        html_url = $1.to_s
        pr_number = $2.to_i
        env = {} of String => String

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
          base_branch: pull_json["base"]["ref"].as_s,
          raw_payload: payload_json.to_json,
          env:         env,
        }]
      end
    end

    def e_status(event, payload_json) : Array(Executable)?
      return L.info "#{event} skip: sender is ap-danger" if payload_json["sender"]["login"] == "ap-danger"

      action = payload_json["state"].as_s
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
          base_branch: pull_json["base"]["ref"].as_s,
          raw_payload: payload_json.to_json,
          env:         env,
        } if pull_json["head"]["sha"].as_s == sha
      end

      executables
    end

    include Executor
  end
end
