module HostedDanger
  class Metrics
    # # HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
    # # TYPE go_memstats_alloc_bytes gauge
    # go_memstats_alloc_bytes 2.21588064e+08

    def create_metrics(name : String, type : String, desc : String, value : String)
      "#HELP #{name} #{desc}\n# TYPE #{name} #{type}\n#{name} #{value}"
    end

    def print(context, params)
      context.response.status_code = 200
      context.response.print create_metrics("hosted-danger-pod-up", "gauge", "Health check of Hosted Danger's Pods", "1")
      context
    end
  end
end
