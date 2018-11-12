require "router"
require "json"
require "./server/web_hook"
require "./server/*"

module HostedDanger
  class Server
    include Router

    def initialize
      @health_check = HealthCheck.new
      @web_hook = WebHook.new
      @git_proxy = GitProxy.new
      @metrics_printer = MetricsPrinter.new
      @exec_openpr = ExecOpenPr.new
    end

    def draw_routes
      # For Health Checking
      get "/" { |context, params| @health_check.check(context, params) }
      get "/status.html" { |context, params| @health_check.check(context, params) }

      # WebHook
      post "/hook" { |context, params| @web_hook.hook(context, params) }
      post "/exec" { |context, params| @exec_openpr.exec(context, params) }

      # Internal Github Proxy
      get "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_get(context, params) }
      post "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_post(context, params) }
      put "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_put(context, params) }
      patch "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_patch(context, params) }
      delete "/proxy/:symbol/*" { |context, params| @git_proxy.proxy_delete(context, params) }

      # Metrics for Prometheus
      get "/metrics" { |context, params| @metrics_printer.print(context, params) }
    end

    def run(host, port)
      server = HTTP::Server.new([
        MetricsHandler.new,
        LogHandler.new,
        HTTP::ErrorHandler.new,
        route_handler,
      ])

      L.info "Start listening on #{host}:#{port}"

      server.bind_tcp(host, port)
      server.listen
    end
  end
end
