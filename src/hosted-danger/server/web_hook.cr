require "json"

module HostedDanger
  alias Executable = NamedTuple(
    event: String,
    html_url: String,
    git_host: String,
    pr_number: Int32,
    access_token: String,
  )

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

      executable? = create_executable(context, payload_json)

      if executable = executable?
        exec_danger(executable)
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

    def create_executable(context, payload_json) : Executable?
      event = context.request.headers["X-GitHub-Event"]

      return e_pull_request(payload_json) if event == "pull_request"
      return e_issue_comment(payload_json) if event == "issue_comment"
      return e_status(payload_json) if event == "status"

      L.info "danger will not be triggered (#{event})"
    end

    def e_pull_request(payload_json) : Executable?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: closed" if payload_json["action"] == "closed"

      event = "pull_request"
      html_url = payload_json["pull_request"]["head"]["repo"]["html_url"].as_s
      git_host = git_host_from_html_url(html_url)
      pr_number = payload_json["number"].as_i
      access_token = access_token_from_git_host(git_host)

      {
        event:        event,
        html_url:     html_url,
        git_host:     git_host,
        pr_number:    pr_number,
        access_token: access_token,
      }
    end

    def e_issue_comment(payload_json) : Executable?
      return L.info "skip: sender is ap-approduce" if payload_json["sender"]["login"] == "ap-approduce"
      return L.info "skip: deleted" if payload_json["action"] == "deleted"

      if payload_json["issue"]["html_url"].as_s =~ /(.*)\/pull\/(.*)/
        ENV["DANGER_PR_COMMENT"] = payload_json["comment"]["body"].as_s

        event = "issue_comment"
        html_url = $1.to_s
        git_host = git_host_from_html_url(html_url)
        pr_number = $2.to_i
        access_token = access_token_from_git_host(git_host)

        return {
          event:        event,
          html_url:     html_url,
          git_host:     git_host,
          pr_number:    pr_number,
          access_token: access_token,
        }
      end

      nil
    end

    def e_status(payload_json) : Executable?
      L.info " ------  STATUS COMINIG!!!!  -------- " # for debug
      return L.info "skip: sender is ap-approduc" if payload_json["sender"]["login"] == "ap-approduce"

      commit_sha = payload_json["sha"].as_s
      L.info "sha: #{commit_sha}"
      html_url = payload_json["repository"]["html_url"].as_s
      L.info "html_url: #{html_url}"
      git_host = git_host_from_html_url(html_url)
      L.info "git_host: #{git_host}"

      org, repo = org_repo_from_html_url(html_url)
      L.info "org: #{org}, repo: #{repo}"

      access_token = access_token_from_git_host(git_host)

      pulls = open_pulls_from_sha(git_host, org, repo, access_token, commit_sha)
      L.info "pulls!!!!!!!!"
      L.info pulls.to_s

      nil
    end

    def git_host_from_html_url(html_url) : String
      if html_url =~ /https:\/\/(.*?)\/.*/
        return $1
      end

      raise "failed to parse the html url: #{html_url} @git_host_from_html_url"
    end

    def access_token_from_git_host(git_host : String) : String
      case git_host
      when "ghe.corp.yahoo.co.jp"
        return ENV["DANGER_GITHUB_API_TOKEN_GHE"]
      when "partner.git.corp.yahoo.co.jp"
        return ENV["DANGER_GITHUB_API_TOKEN_PARTNER"]
      end

      raise "failed to find an access_token for #{git_host}"
    end

    def org_repo_from_html_url(html_url) : Array(String)
      if html_url =~ /https:\/\/.*?\/(.*?)\/(.*)/
        return [$1.to_s, $2.to_s]
      end

      raise "failed to parse the html url: #{html_url} @org_repo_from_html_url"
    end

    def open_pulls_from_sha(git_host : String, org : String, repo : String, access_token : String, sha : String) : String
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls?state=open"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)
      res.body
    end

    include Executor
  end
end
