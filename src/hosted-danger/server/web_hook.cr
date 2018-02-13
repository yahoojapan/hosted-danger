require "json"

module HostedDanger
  class WebHook
    def initialize
    end

    def hook(context, params)
      payload : String = if body = context.request.body
        body.gets_to_end
      else
        raise "Empty body"
      end

      payload_json = JSON.parse(payload)

      unless payload_json["action"]? && payload_json["number"]? && payload_json["pull_request"]?
        L.info "This is not a Pull Request"

        context.response.status_code = 200
        return context
      end

      L.info "This is a Pull Request"

      exec_danger(payload_json)

      context.response.status_code = 200
      context.response.print "OK"
      context
    rescue e : Exception
      L.error e.message.not_nil!

      context.response.status_code = 400
      context.response.print "Bad Request"
      context
    end

    include Executor
  end
end
