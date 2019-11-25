module HostedDanger
  class Prometheus
    SPANS = [
      Time::Span.new(0, 10, 0),
      Time::Span.new(0, 5, 0),
      Time::Span.new(0, 1, 0),
    ]

    def initialize
    end

    def count_by_event(span : Time::Span) : MetricsPrinter
      m = MetricsQueue.get_instance.count_by_event(span)

      total = MetricsPrintable.new(m[:total], "_total", nil)
      events = m[:events]
               .map { |event, count| MetricsPrintable.new(count.as(Int32), nil, {"event" => event.as(String)}) }

      MetricsPrinter.new(
        "hd_count_by_event_#{span.minutes}_mins_#{span.seconds}_secs",
        "count events by event name",
        "counter",
        [total, events].flatten,
      )
    end

    def count_by_status(span : Time::Span) : MetricsPrinter
      m = MetricsQueue.get_instance.count_by_status(span)

      total = MetricsPrintable.new(m[:total], "_total", nil)
      error_ratio = MetricsPrintable.new(m[:error_ratio], "_error_ratio", nil)

      events = m[:events]
               .map { |status, count| MetricsPrintable.new(count.as(Int32), nil, {"status" => status.as(String)}) }

      MetricsPrinter.new(
        "hd_count_by_status_#{span.minutes}_mins_#{span.seconds}_secs",
        "count events by event name",
        "counter",
        [total, error_ratio, events].flatten,
      )
    end

    def queue_capacity : MetricsPrinter
      m = MetricsQueue.get_instance
      o = MetricsPrintable.new(m.capacity_over? ? 1 : 0, "_over", nil)
      c = MetricsPrintable.new(m.size, "_size", nil)

      MetricsPrinter.new(
        "hd_metrics_queue_capacity",
        "capacity of the metrics queue",
        "gauge",
        [o, c]
      )
    end

    def serve(context, params)
      ms = SPANS.map { |span| [count_by_event(span), count_by_status(span), queue_capacity] }.flatten.map { |m| "#{m}" }.join("\n")

      context.response.status_code = 200
      context.response.print ms
      context
    end
  end

  # go_gc_duration_seconds{quantile="0.25"} 0.000113202
  # go_gc_duration_seconds[suffix]{ [query] } [value]
  class MetricsPrintable
    def initialize(@value : Int32 | Float64, @suffix : String | Nil, @query : Hash(String, String) | Nil)
    end

    def query_to_s : String
      if query = @query
        qs = query.map { |k, v| "#{k}=\"#{v}\"" }.join(",")
        "{#{qs}}"
      else
        ""
      end
    end

    def to_s(io)
      io << "#{@suffix}#{query_to_s} #{@value}"
    end
  end

  class MetricsPrinter
    def initialize(
         @name : String,
         @description : String,
         @type : String,
         @metrics : Array(MetricsPrintable)
       )
    end

    def to_s(io)
      io << to_s_inner
    end

    def to_s_inner : String
      h = "# HELP #{@name} #{@description}"
      t = "# TYPE #{@name} #{@type}"
      m = @metrics.map { |m| "#{@name}#{m}" }.join("\n")

      [h, t, m].join("\n")
    end
  end
end
