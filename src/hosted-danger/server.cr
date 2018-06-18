require "router"
require "json"
require "./server/*"

module HostedDanger
  class Server
    include Router

    def initialize
      @health_check = HealthCheck.new
      @web_hook = WebHook.new
      @git_proxy = GitProxy.new
      @sd_proxy = SDProxy.new
      @metrics_printer = MetricsPrinter.new
    end

    def draw_routes
      # For Health Checking
      get "/" { |context, params| @health_check.check(context, params) }
      get "/status.html" { |context, params| @health_check.check(context, params) }

      # WebHook
      post "/hook" { |context, params| @web_hook.hook(context, params) }

      # Internal Github Proxy
      get "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_get(context, params) }
      post "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_post(context, params) }
      put "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_put(context, params) }
      patch "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_patch(context, params) }
      delete "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_delete(context, params) }

      # Internal Screwdriver.cd Proxy
      get "/sdproxy/auth" { |context, params| @sd_proxy.auth(context, params) }
      get "/sdproxy/auth/next" { |context, params| @sd_proxy.auth_next(context, params) }

      # Metrics for Prometheus
      get "/metrics" { |context, params| @metrics_printer.print(context, params) }
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
