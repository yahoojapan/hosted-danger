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

    record MetricsContent, type : String, desc : String, value : Int32 | UInt32 | Float64 do
      setter value : Int32 | UInt32 | Float64
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
      @contents[name] = MetricsContent.new(type, desc, 0_u32)
    end

    def set(name : String, value)
      @contents[name].value = value
    end

    def increment(name : String)
      @contents[name].value += 1_u32
    end

    def to_s : String
      set("pod_time", duration)

      res = [] of String

      @contents.each do |k, v|
        metrics_name = "#{prefix}_#{k}"

        res << "# HELP #{metrics_name} #{v.desc}\n# TYPE #{metrics_name} #{v.type}\n#{metrics_name} #{v.value}\n"
      end

      res.join("\n")
    end

    private def duration
      (Time.now - @launch_time).seconds
    end

    private def prefix : String
      "hosted_danger"
    end
  end
end
