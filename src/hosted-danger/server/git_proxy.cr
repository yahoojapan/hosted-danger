module HostedDanger
  class GitProxy
    # TODO: support partner and git.corp
    # idea set each host durating the initialization

    # TODO: spec for this
    def rewrite_headers(context) : HTTP::Headers
      override_headers = HTTP::Headers.new
      override_headers["Host"] = "ghe.corp.yahoo.co.jp"
      override_headers["Authorization"] = "token beb2dd00f39995703ea60915b7d7d3c7e15aec34"
      override_headers["Content-Type"] = "application/json" if context.request.method.downcase == "post"

      context.request.headers.merge!(override_headers)
    end

    # TODO: spec for this
    def rewrite_resource(context) : String
      resource = context.request.resource.lchop("/proxy/")
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

      res = HTTP::Client.get("https://ghe.corp.yahoo.co.jp/api/v3/#{resource}", headers)

      context.response.status_code = res.status_code
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

      res = HTTP::Client.post("https://ghe.corp.yahoo.co.jp/api/v3/#{resource}", headers, payload)

      context.response.status_code = res.status_code
      context.response.print res.body
      context
    end
  end
end
