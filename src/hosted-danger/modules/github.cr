module HostedDanger
  module Github
    module State
      ERROR   = "error"
      FAILURE = "failure"
      PENDING = "pending"
      SUCCESS = "success"
    end

    class GithubException < Exception; end

    def pull_request_open?(git_host : String, org : String, repo : String, pr_number : Int32, access_token : String) : Bool
      pull_json = pull_request(git_host, org, repo, pr_number, access_token)
      pull_json["state"].as_s == "open"
    rescue e : Exception
      L.error e, pull_json.to_s

      true
    end

    def pull_request(git_host : String, org : String, repo : String, pr_number : Int32, access_token : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls/#{pr_number}"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      validate_github_result(res)

      JSON.parse(res.body)
    end

    def pull_requests(git_host : String, org : String, repo : String, access_token : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls?state=open"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      validate_github_result(res)

      JSON.parse(res.body)
    end

    def issue_comments(git_host : String, org : String, repo : String, pr_number : Int32, access_token : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/issues/#{pr_number}/comments"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      validate_github_result(res)

      JSON.parse(res.body)
    end

    def delete_comment(git_host : String, org : String, repo : String, comment_id : Int32, access_token : String)
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/issues/comments/#{comment_id}"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.delete(url, headers)

      validate_github_result(res)

      res
    end

    def build_state_of(
      git_host : String,
      org : String,
      repo : String,
      sha : String,
      access_token : String
    ) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/commits/#{sha}/statuses"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      validate_github_result(res)

      JSON.parse(res.body)
    end

    def build_state(
      git_host : String,
      org : String,
      repo : String,
      sha : String,
      description : String,
      access_token : String,
      state : String,
      log_url : String? = nil,
      context : String = "danger/#{DANGER_ID}"
    )
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/statuses/#{sha}"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      target_url = if _log_url = log_url
                     _log_url
                   else
                     "https://#{git_host}/#{org}/#{repo}/commit/#{sha}"
                   end

      body = {
        state:       state,
        target_url:  target_url,
        description: description,
        context:     context,
      }.to_json

      res = HTTP::Client.post(url, headers, body)

      validate_github_result(res)

      JSON.parse(res.body)
    end

    def validate_github_result(res : HTTP::Client::Response)
      p "----------------- res ------------------------"
      p res.status_code
      p res
    end
  end
end
