module HostedDanger
  class LogHandler
    include HTTP::Handler

    def call(context : HTTP::Server::Context)
      L.info "[#{context.request.method}] #{context.request.resource}"
      call_next(context)
    end
  end
end
