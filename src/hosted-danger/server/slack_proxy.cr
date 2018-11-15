module HostedDanger
  alias SlackPayload = {text: String, channel: String}

  class SlackProxy
    def post(context, params)
      if payload = context.request.body.try &.gets_to_end
        p payload

        slack_payload = SlackPayload.from_json(payload)

        p slack_payload

        L.info "slack (##{slack_payload[:channel]}): #{slack_payload[:text]}"

        headers = HTTP::Headers.new
        headers["Authorization"] = "Bearer #{ServerConfig.secret("slack_bot_token")}"
        headers["Content-Type"] = "application/json"

        p headers

        res = HTTP::Client.post("https://slack.com/api/chat.postMessage", headers, slack_payload.to_json)

        p res

        context.response.status_code = res.status_code
      else
        context.response.status_code = 400
      end

      context
    end
  end
end
