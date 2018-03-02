module HostedDanger
  class GitProxy
    alias GitContext = NamedTuple(symbol: String, git_host: String, access_token: String)

    def rewrite_headers(context, git_context : GitContext) : HTTP::Headers
      override_headers = HTTP::Headers.new
      override_headers["Host"] = git_context[:git_host]
      override_headers["Authorization"] = "token #{git_context[:access_token]}"

      context.request.headers.merge!(override_headers)
    end

    def rewrite_resource(context, git_context : GitContext) : String
      resource = context.request.resource.lchop("/proxy").lchop("/#{git_context[:symbol]}/")
      resource
    end

    def convert_body(body : String, git_context : GitContext) : String
      body_json = JSON.parse(body)

      # RubyのDangerがここで直接 _links -> issue -> href を参照しているため
      # ここだけproxyのURLに置き換える
      # https://github.com/danger/danger/blob/250988a1ac5e93b8c3c9b6da5bd0fb5e737348a4/lib/danger/request_sources/github/github.rb#L131
      if body_json["_links"]["issue"]["href"]?
        _links_issue_href = body_json["_links"]["issue"]["href"].as_s.sub(
          "https://#{git_context[:git_host]}/api/v3",
          "http://localhost/proxy/#{git_context[:symbol]}",
        )

        body_json["_links"]["issue"].as_h["href"] = _links_issue_href
      end

      body_json.to_json
    end

    def proxy_get(context, params)
      git_context = get_git_context(params)
      puts "-------------------- context --------------------"
      p context

      puts "-------------------- git_context --------------------"
      puts git_context

      headers = rewrite_headers(context, git_context)
      puts "-------------------- headers --------------------"
      puts headers

      resource = rewrite_resource(context, git_context)
      puts "-------------------- resource --------------------"
      puts resource
      puts "https://#{git_context[:git_host]}/api/v3/#{resource}"

      res = HTTP::Client.get("https://#{git_context[:git_host]}/api/v3/#{resource}", headers)
      puts "-------------------- res --------------------"
      p res

      context.response.status_code = res.status_code
      context.response.content_type = "application/vnd.github.v3+json"
      context.response.print convert_body(res.body, git_context)
      context
    end

    def proxy_post(context, params)
      git_context = get_git_context(params)

      headers = rewrite_headers(context, git_context)
      resource = rewrite_resource(context, git_context)
      payload = context.request.body.try &.gets_to_end

      res = HTTP::Client.post("https://#{git_context[:git_host]}/api/v3/#{resource}", headers, payload)

      context.response.status_code = res.status_code
      context.response.content_type = "application/vnd.github.v3+json"
      context.response.print convert_body(res.body, git_context)
      context
    end

    def proxy_patch(context, params)
      git_context = get_git_context(params)

      headers = rewrite_headers(context, git_context)
      resource = rewrite_resource(context, git_context)
      payload = context.request.body.try &.gets_to_end

      res = HTTP::Client.patch("https://#{git_context[:git_host]}/api/v3/#{resource}", headers, payload)

      context.response.status_code = res.status_code
      context.response.content_type = "application/vnd.github.v3+json"
      context.response.print convert_body(res.body, git_context)
      context
    end

    def get_git_context(params : Hash(String, String)) : GitContext
      symbol = params["symbol"]

      git_host = case symbol
                 when "ghe"
                   "ghe.corp.yahoo.co.jp"
                 when "partner"
                   "partner.git.corp.yahoo.co.jp"
                 when "git"
                   "git.corp.yahoo.co.jp"
                 else
                   raise "Invalid symbol @get_git_context: #{symbol}"
                 end

      access_token = access_token_from_git_host(git_host)

      {
        symbol:       symbol,
        git_host:     git_host,
        access_token: access_token,
      }
    end

    include Parser
  end
end
