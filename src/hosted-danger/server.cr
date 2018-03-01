require "router"
require "json"
require "./server/*"

module HostedDanger
  class Server
    include Router

    def initialize
      @health_check = HealthCheck.new
      @web_hook = WebHook.new

      @ghe_proxy = GitProxy.new("ghe.corp.yahoo.co.jp")
      @partner_proxy = GitProxy.new("partner.git.corp.yahoo.co.jp")
      @git_proxy = GitProxy.new("git.corp.yahoo.co.jp")
    end

    def draw_routes
      # For Health Checking
      get "/" { |context, params| @health_check.check(context, params) }
      get "/status.html" { |context, params| @health_check.check(context, params) }

      # WebHook
      post "/hook" { |context, params| @web_hook.hook(context, params) }

      # Internal Proxy
      get "/proxy/ghe/*" { |context, params| @ghe_proxy.proxy_get(context, params) }
      get "/proxy/partner/*" { |context, params| @partner_proxy.proxy_get(context, params) }
      get "/proxy/git/*" { |context, params| @git_proxy.proxy_get(context, params) }
      post "/proxy/ghe/*" { |context, params| @ghe_proxy.proxy_post(context, params) }
      post "/proxy/partner/*" { |context, params| @partner_proxy.proxy_post(context, params) }
      post "/proxy/git/*" { |context, params| @git_proxy.proxy_post(context, params) }
      patch "/proxy/ghe/*" { |context, params| @ghe_proxy.proxy_patch(context, params) }
      patch "/proxy/partner/*" { |context, params| @partner_proxy.proxy_patch(context, params) }
      patch "/proxy/git/*" { |context, params| @git_proxy.proxy_patch(context, params) }
    end

    def run
      server = HTTP::Server.new("0.0.0.0", 80, [
        LogHandler.new,
        HTTP::ErrorHandler.new,
        route_handler,
      ])
      server.listen
    end
  end
end
