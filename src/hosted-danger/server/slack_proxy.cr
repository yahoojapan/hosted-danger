module HostedDanger
  alias SlackPayload = {text: String, channel: String}

  class SlackProxy
    def post(context, params)
      if payload = context.request.body.try &.gets_to_end
        slack_payload = SlackPayload.from_json(payload)

        L.info "slack (##{slack_payload[:channel]}): #{slack_payload[:text]}"

        headers = HTTP::Headers.new
        headers["Authorization"] = "Bearer #{ServerConfig.secret("slack_bot_token")}"
        headers["Content-Type"] = "application/json"

        res = HTTP::Client.post("https://slack.com/api/chat.postMessage", headers, slack_payload.to_json)

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
