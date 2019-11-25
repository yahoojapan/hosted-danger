module HostedDanger
  class MetricsQueue
    QUEUE_ACTIVE_DURATION     = Time::Span.new(0, 10, 0)
    QUEUE_CLEAN_INTERVAL_SECS =   60
    QUEUE_CAPACITY_LIMIT      = 1000

    @@metrics_queue : MetricsQueue | Nil = nil

    # MetricsQueue is Singleton
    def self.get_instance : MetricsQueue
      @@metrics_queue ||= MetricsQueue.new
      @@metrics_queue.not_nil!
    end

    protected def initialize(@inner = [] of ExecutionMetrics)
      spawn do
        loop do
          clean
          sleep QUEUE_CLEAN_INTERVAL_SECS
        end
      end
    end

    def push(m : ExecutionMetrics)
      @inner.push(m)
      @inner.shift if @inner.size > QUEUE_CAPACITY_LIMIT
    end

    def size : Int32
      @inner.size
    end

    alias CountByEvent = NamedTuple(total: Int32, events: Hash(String | Int32, String | Int32))
    alias CountByStatus = NamedTuple(total: Int32, error_ratio: Float64, events: Hash(String | Int32, String | Int32))

    def count_by_span(span : Time::Span) : Array(ExecutionMetrics)
      @inner.select { |e| Time.utc - Time.unix(e.timestamp) <= span }
    end

    def count_by_event(span : Time::Span) : CountByEvent
      events = count_by_span(span)

      total = events.size

      events = events
               .group_by { |e| e.event }
               .map { |name, events| [name, events.size] }
               .to_h

      {
        total:  total,
        events: events,
      }
    end

    def count_by_status(span : Time::Span) : CountByStatus
      events = count_by_span(span)

      total = events.size

      events = events
               .group_by { |e| e.status }
               .map { |status, events| [status, events.size] }
               .to_h

      e = events.has_key?("error") ? events["error"].as(Int32) : 0
      s = events.has_key?("success") ? events["success"].as(Int32) : 0

      error_ratio = if e + s > 0
                      e / (e + s)
                    else
                      0.0
                    end

      {
        total:       total,
        error_ratio: error_ratio,
        events:      events,
      }
    end

    def clean
      @inner.reject! { |e| Time.utc - Time.unix(e.timestamp) > QUEUE_ACTIVE_DURATION }
    end

    def clear
      @inner.clear
    end

    def capacity_over?
      @inner.size >= QUEUE_CAPACITY_LIMIT
    end
  end

  class ExecutionMetrics
    getter event : String
    getter repo : String
    getter timestamp : Int64
    property status : String

    def initialize(
         @event : String,
         @repo : String,
         @timestamp : Int64,
         @status : String
       )
    end
  end
end
