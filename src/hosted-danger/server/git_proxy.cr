module HostedDanger
  class GitProxy
    @access_token : String

    # TODO: support partner and git.corp
    # idea set each host durating the initialization
    def initialize(@git_host : String)
      @access_token = access_token_from_git_host(@git_host)
    end

    # TODO: spec for this
    def rewrite_headers(context) : HTTP::Headers
      override_headers = HTTP::Headers.new
      override_headers["Host"] = @git_host
      override_headers["Authorization"] = "token #{@access_token}"

      context.request.headers.merge!(override_headers)
    end

    # TODO: spec for this
    def rewrite_resource(context) : String
      resource = context.request.resource
                                .lchop("/proxy")
                                .lchop("/ghe/")
                                .lchop("/partner/")
                                .lchop("/git/")
      resource
    end

    def proxy_get(context, params)
      puts "------PROXY GET------"
      p context

      headers = rewrite_headers(context)
      puts "------------------------ rewrite_headers"
      puts headers

      resource = rewrite_resource(context)
      puts "------------------------ resource"
      puts resource

      res = HTTP::Client.get("https://#{@git_host}/api/v3/#{resource}", headers)

      puts res

      context.response.status_code = res.status_code
      context.response.content_type = "application/json"
      context.response.print res.body
      context
    end

    def proxy_post(context, params)
      puts "------PROXY POST------"
      p context

      headers = rewrite_headers(context)
      puts "------------------------ rewrite_headers"
      puts headers

      resource = rewrite_resource(context)

      puts "------------------------ resource"
      puts resource

      payload = context.request.body.try &.gets_to_end
      puts "------------------------ payload"
      puts payload

      res = HTTP::Client.post("https://#{@git_host}/api/v3/#{resource}", headers, payload)

      puts res

      context.response.status_code = res.status_code
      context.response.content_type = "application/json"
      context.response.print res.body
      context
    end

    def proxy_patch(context, params)
      puts "------PROXY PATCH------"
      p context

      headers = rewrite_headers(context)
      puts "------------------------ rewrite_headers"
      puts headers

      resource = rewrite_resource(context)

      puts "------------------------ resource"
      puts resource

      payload = context.request.body.try &.gets_to_end
      puts "------------------------ payload"
      puts payload

      res = HTTP::Client.patch("https://#{@git_host}/api/v3/#{resource}", headers, payload)

      puts res

      context.response.status_code = res.status_code
      context.response.content_type = "application/json"
      context.response.print res.body
      context
    end

    include Parser
  end
end
