require "json"

module HostedDanger
  class WebHook
    def initialize
    end

    def hook(context, params)
      event = context.request.headers["X-GitHub-Event"]

      payload : String = if body = context.request.body
        body.gets_to_end
      else
        raise "Empty body"
      end

      payload_json = JSON.parse(payload)

      if event != "pull_request"
        L.info "The event #{event} is not triggerd"

        context.response.status_code = 200
        return context
      end

      unless payload_json["issue"]["state"]? == "open"
        L.info "Pull Request is not open"

        context.response.status_code = 200
        return context
      end

      L.info "Danger will be triggered"

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
