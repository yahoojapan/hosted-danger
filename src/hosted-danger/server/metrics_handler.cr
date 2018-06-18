module HostedDanger
  class MetricsHandler
    include HTTP::Handler

    def initialize
    end

    def call(context : HTTP::Server::Context)
      call_next(context)
    end
  end
end
