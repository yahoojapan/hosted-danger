module HostedDanger
  class MetricsPrinter
    @launch_time : Time

    def initialize(@web_hook : WebHook)
      @launch_time = Time.now
    end

    def duration : Int32
      (Time.now - @launch_time).seconds
    end

    def print(context, params)
      metrics = Metrics.new
                       .add("pod_up", "gauge", "Health check of Hosted Danger's Pods", 1)
                       .add("pod_time", "counter", "Up time for the pod (seconds)", duration)

      @web_hook.requests.each do |k, v|
        metrics.add(k, "counter", "Number of requests for #{k} event", v)
      end

      context.response.headers["Content-Type"] = "text/plain"
      context.response.status_code = 200
      context.response.print metrics.to_s
      context
    end

    class Metrics
      @contents = [] of String

      def initialize
      end

      def add(name : String, type : String, desc : String, value) : Metrics
        metrics_name = "#{prefix}_#{name}"
        @contents << "# HELP #{metrics_name} #{desc}\n# TYPE #{metrics_name} #{type}\n#{metrics_name} #{value}"

        self
      end

      def prefix : String
        "hosted_danger"
      end

      def to_s
        @contents.join("\n")
      end
    end
  end
end
