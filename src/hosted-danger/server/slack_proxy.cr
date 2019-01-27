module HostedDanger
  class SlackProxy
    def post(context, params)
      if payload = context.request.body.try &.gets_to_end
        L.info "slack (#{payload})"

        headers = HTTP::Headers.new
        headers["Authorization"] = "Bearer #{ServerConfig.secret("slack_bot_token")}"
        headers["Content-Type"] = "application/json; charset=UTF-8"

        res = HTTP::Client.post("https://slack.com/api/chat.postMessage", headers, payload)

        context.response.status_code = res.status_code
      else
        context.response.status_code = 400
      end

      context
    rescue e : Exception
      L.error e, payload.not_nil! if payload

      context.response.status_code = 500
      context
    end
  end
end
