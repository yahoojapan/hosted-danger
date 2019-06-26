module HostedDanger
  class GitProxy
    alias GitContext = NamedTuple(symbol: String, git_host: String, access_token: String)

    class AuthException < Exception; end

    def forbidden(context, e : AuthException) : HTTP::Server::Context
      context.response.status_code = 403

      if msg = e.message
        L.error msg

        context.response.print e.message
      end

      context
    end

    def auth(context, resource : String, method : String)
      if authorization = context.request.headers["Authorization"]?
        if authorization =~ /token\s(.+)/
          org = $1

          if resource =~ /repos\/.+?\/.+?\/contents.*/ && (method == "PUT" || method == "DELETE")
            raise AuthException.new("CREATE, UPDATE, DELETE contents from Dangerfile is not allowed.")
          end

          if resource =~ /repos\/(.*?)\/(.*?)\/.*/
            return if org == $1
            return if "#{$1}/#{$2}" == "yahoojapan/hosted-danger"
            raise AuthException.new("ACCESS DINIED: #{org} => #{$1}/#{$2} (#{resource})")
          else
            return
          end
        end
      end
      raise AuthException.new("ACCESS DINIED: No Authorization Header (#{resource})")
    end

    def api_base(git_context : GitContext) : String
      ServerConfig.githubs.find { |g| g.host == git_context[:git_host] }.not_nil!.api_base
    end

    def rewrite_headers(context, git_context : GitContext) : HTTP::Headers
      override_headers = HTTP::Headers.new
      # override_headers["Host"] = git_context[:git_host]
      override_headers["Authorization"] = "token #{git_context[:access_token]}"

      h = context.request.headers.merge!(override_headers)
      h.delete("Accept-Encoding")
      h.delete("Host")
      h
    end

    def rewrite_resource(context, git_context : GitContext) : String
      resource = context.request.resource.lchop("/proxy").lchop("/#{git_context[:symbol]}/")
      resource
    end

    def convert_body(_body : String?, git_context : GitContext) : String?
      return nil unless body = _body
      return nil if body.size == 0

      body_json = JSON.parse(body)

      #
      # https://github.com/danger/danger/blob/250988a1ac5e93b8c3c9b6da5bd0fb5e737348a4/lib/danger/request_sources/github/github.rb#L131
      #
      if body_json.as_h? &&
         body_json["_links"]? &&
         body_json["_links"]["issue"]? &&
         body_json["_links"]["issue"]["href"]?
        _links_issue_href = body_json["_links"]["issue"]["href"].as_s.sub(
          api_base(git_context),
          "http://localhost/proxy/#{git_context[:symbol]}",
        )

        body_json["_links"]["issue"].as_h["href"] = JSON::Any.new(_links_issue_href)
      end

      body_json.to_json
    rescue e : JSON::ParseException
      # The payload might not be json structure.
      # For example: Content-Type: application/vnd.github.v3.diff
      _body
    rescue e : Exception
      error_message = "Error at @convert_body"
      error_message += e.message.not_nil! if e.message

      L.error error_message

      _body
    end

    def write_headers(context, git_context, response) : HTTP::Server::Context
      response.headers.each do |k, v|
        if k == "Link"
          #
          # Replace the urls in header into proxy.
          # The urls are refered from danger.
          #
          context.response.headers[k] = if v.is_a?(Array)
                                          v.map { |_v| _v.gsub(api_base(git_context), "http://localhost/proxy/#{git_context[:symbol]}") }
                                        else
                                          v.as(String).gsub(api_base(git_context), "http://localhost/proxy/#{git_context[:symbol]}")
                                        end
        elsif k == "Content-Encoding" || k == "Transfer-Encoding"
          next
        else
          context.response.headers[k] = v
        end
      end

      context
    end

    def proxy_get(context, params)
      git_context = get_git_context(params)

      resource = rewrite_resource(context, git_context)

      auth(context, resource, "GET")

      headers = rewrite_headers(context, git_context)

      res = HTTP::Client.get("#{api_base(git_context)}/#{resource}", headers)

      write_headers(context, git_context, res)

      context.response.status_code = res.status_code
      context.response.print convert_body(res.body, git_context)
      context
    rescue e : AuthException
      forbidden(context, e)
    end

    def proxy_post(context, params)
      git_context = get_git_context(params)

      resource = rewrite_resource(context, git_context)

      auth(context, resource, "POST")

      headers = rewrite_headers(context, git_context)
      payload = context.request.body.try &.gets_to_end

      res = HTTP::Client.post("#{api_base(git_context)}/#{resource}", headers, payload)

      write_headers(context, git_context, res)

      context.response.status_code = res.status_code
      context.response.print convert_body(res.body, git_context)
      context
    rescue e : AuthException
      forbidden(context, e)
    end

    def proxy_put(context, params)
      git_context = get_git_context(params)

      resource = rewrite_resource(context, git_context)

      auth(context, resource, "PUT")

      headers = rewrite_headers(context, git_context)
      payload = context.request.body.try &.gets_to_end

      res = HTTP::Client.put("#{api_base(git_context)}/#{resource}", headers, payload)

      write_headers(context, git_context, res)

      context.response.status_code = res.status_code
      context.response.print convert_body(res.body, git_context)
      context
    rescue e : AuthException
      forbidden(context, e)
    end

    def proxy_patch(context, params)
      git_context = get_git_context(params)

      resource = rewrite_resource(context, git_context)

      auth(context, resource, "PATCH")

      headers = rewrite_headers(context, git_context)
      payload = context.request.body.try &.gets_to_end

      res = HTTP::Client.patch("#{api_base(git_context)}/#{resource}", headers, payload)

      write_headers(context, git_context, res)

      context.response.status_code = res.status_code
      context.response.print convert_body(res.body, git_context)
      context
    rescue e : AuthException
      forbidden(context, e)
    end

    def proxy_delete(context, params)
      git_context = get_git_context(params)

      resource = rewrite_resource(context, git_context)

      auth(context, resource, "DELETE")

      headers = HTTP::Headers.new
      headers["Authorization"] = "token #{git_context[:access_token]}"

      res = HTTP::Client.delete("#{api_base(git_context)}/#{resource}", headers)

      write_headers(context, git_context, res)

      context.response.status_code = res.status_code
      context.response.print convert_body(res.body, git_context)
      context
    rescue e : AuthException
      forbidden(context, e)
    end

    def get_git_context(params : Hash(String, String)) : GitContext
      symbol = params["symbol"]
      git_host = ServerConfig.symbol_to_git_host(symbol)
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
