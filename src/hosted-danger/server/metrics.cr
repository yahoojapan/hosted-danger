module HostedDanger
  class MetricsPrinter
    @launch_time : Time

    def initialize
      @launch_time = Time.now
    end

    def duration : Int32
      (Time.now - @launch_time).seconds
    end

    def print(context, params)
      metrics = Metrics.new
                       .add("hosted-danger-pod-up", "gauge", "Health check of Hosted Danger's Pods", "1")
      # .add("hosted-danger-pod-time", "counter", "Up time for the pod", duration.to_s)

      context.response.headers["Content-Type"] = "text/plain"
      context.response.status_code = 200
      context.response.print metrics.to_s
      context
    end

    class Metrics
      @contents = [] of String

      def initialize
      end

      def add(name : String, type : String, desc : String, value : String) : Metrics
        @contents << "# HELP #{name} #{desc}\n# TYPE #{name} #{type}\n#{name} #{value}"

        self
      end

      def to_s
        @contents.join("\n")
      end
    end
  end
end
