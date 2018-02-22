module HostedDanger
  module Parser
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

    def open_pulls_from_sha(git_host : String, org : String, repo : String, access_token : String, sha : String) : JSON::Any
      url = "https://#{git_host}/api/v3/repos/#{org}/#{repo}/pulls?state=open"

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{access_token}"

      res = HTTP::Client.get(url, headers)

      JSON.parse(res.body)
    end
  end
end