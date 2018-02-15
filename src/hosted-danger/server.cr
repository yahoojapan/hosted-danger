require "router"
require "./server/*"

module HostedDanger
  class Server
    include Router

    def initialize
      @health_check = HealthCheck.new
      @web_hook = WebHook.new
    end

    def draw_routes
      # For Health Checking
      get "/" { |context, params| @health_check.check(context, params) }
      get "/status.html" { |context, params| @health_check.check(context, params) }

      # WebHook
      post "/hook" { |context, params| @web_hook.hook(context, params) }
    end

    def run
      server = HTTP::Server.new("0.0.0.0", port, [
        HTTP::ErrorHandler.new,
        route_handler,
      ])
      server.listen
    end

    def port
      ENV.has_key?("HD_PORT") ? ENV["HD_PORT"].to_i : 80
    end
  end
end
