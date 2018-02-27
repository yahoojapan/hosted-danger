module HostedDangerMocks
  module Parser
    def git_host_from_html_url(html_url) : String
      ""
    end

    def access_token_from_git_host(git_host : String) : String
      ""
    end

    def org_repo_from_html_url(html_url) : Array(String)
      ["", ""]
    end

    def remote_from_html_url(html_url : String, access_token : String) : String
      ""
    end
  end
end
