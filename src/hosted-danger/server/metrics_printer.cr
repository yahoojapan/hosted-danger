module HostedDanger
  class MetricsPrinter
    def initialize
    end

    def print(context, params)
      context.response.headers["Content-Type"] = "text/plain"
      context.response.status_code = 200
      context.response.print Metrics.to_s
      context
    end
  end
end
