module HostedDanger
  module Parser
    def git_host_from_html_url(html_url) : String
      if html_url =~ /(https:\/\/(.*@|)|git@|)(.*?)(:|\/).*/
        return $3
      end

      raise "failed to parse the html url: #{html_url} @git_host_from_html_url"
    end

    def access_token_from_git_host(git_host : String) : String
      ServerConfig.access_token_of(git_host)
    end

    def org_repo_from_html_url(html_url) : Array(String)
      if html_url =~ /(https:\/\/.*?\/|git@.*?:)(.*?)\/(.*)/
        return [$2.to_s, $3.to_s]
      end

      raise "failed to parse the html url: #{html_url} @org_repo_from_html_url"
    end

    def remote_from_html_url(html_url : String, access_token : String) : String
      git_host = git_host_from_html_url(html_url)
      app_user = ServerConfig.app_user(git_host)

      if html_url =~ /https:\/\/(.*)/
        return "https://#{app_user}:#{access_token}@#{$1}"
      end

      raise "invalid html_url #{html_url} @remote_from_html_url"
    end

    def git_url_from_api_url(api_url : String) : String
      if github = ServerConfig.githubs.find { |g| api_url.starts_with?(g.api_base) }
        if api_url =~ /#{github.api_base}\/repos\/(.*?)\/(.*?)\/.*/
          return "https://#{github.host}/#{$1}/#{$2}"
        end
      end

      raise "unable to find matched github(API_URL=#{api_url})"
    end
  end
end
