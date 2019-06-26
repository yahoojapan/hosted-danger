module HostedDanger
  class HealthCheck
    def initialize
    end

    def check(context, params)
      context.response.status_code = 200
      context.response.print "ok"
      context
    end
  end
end
