module HostedDanger
  class Metrics
    @@instance : Metrics?

    def self.instance : Metrics
      @@instance ||= Metrics.new
      @@instance.not_nil!
    end

    def self.register(name : String, type : String, desc : String)
      instance.register(name, type, desc)
    end

    def self.set(name : String, value)
      instance.set(name, value)
    end

    def self.increment(name : String)
      instance.increment(name)
    end

    def self.to_s
      instance.to_s
    end

    @contents : Hash(String, MetricsContent) = {} of String => MetricsContent

    @launch_time : Time

    def initialize
      @launch_time = Time.now

      register("pod_up", "gauge", "Health check of Hosted Danger's Pods")
      register("pod_time", "counter", "Up time for the pod (seconds)")

      set("pod_up", 1_u32)
    end

    def register(name : String, type : String, desc : String)
      @contents[name] = MetricsContent.new(name, type, desc, 0_u32)
    end

    def set(name : String, value)
      @contents[name].value = value
    end

    def increment(name : String)
      @contents[name].value += 1_u32
    end

    def to_s : String
      set("pod_time", duration)

      @contents.values.map(&.to_s).join("\n")
    end

    private def duration
      (Time.now - @launch_time).seconds
    end

    class MetricsContent
      alias Valueable = Int32 | UInt32 | Float64

      property value : Valueable

      def initialize(@name : String, @type : String, @desc : String, @value : Valueable)
      end

      def to_s : String
        metrics_name = "#{prefix}_#{@name}"

        "# HELP #{metrics_name} #{@desc}\n# TYPE #{metrics_name} #{@type}\n#{metrics_name} #{@value}\n"
      end

      private def prefix : String
        "hosted_danger"
      end
    end
  end
end
