module HostedDanger
  module Github
    module State
      ERROR   = "error"
      FAILURE = "failure"
      PENDING = "pending"
      SUCCESS = "success"
    end

    def pull_request_open?(git_host : String, org : String, repo : String, pr_number : Int32, access_token : String) : Bool
      pull_json = pull_request(git_host, org, repo, pr_number, access_token)
      pull_json["state"].as_s == "open"
    end

    def pull_request(git_host : String, org : String, repo : String, pr_number : Int32, access_token : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls/#{pr_number}"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      JSON.parse(res.body)
    end

    def pull_requests(git_host : String, org : String, repo : String, access_token : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls?state=open"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      JSON.parse(res.body)
    end

    def build_state_of(
          git_host : String,
          org : String,
          repo : String,
          sha : String,
          access_token : String,
        )
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/commits/#{sha}/statuses"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

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

      JSON.parse(res.body)
    end
  end
end
