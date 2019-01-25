require 'net/https'
require 'json'

module Danger
  class DangerSlack < Plugin
    ENDPOINT = 'http://localhost/slack'.freeze

    def post(text, channel)
      uri = URI.parse(ENDPOINT)

      http = Net::HTTP.new(uri.host, uri.port)

      req = Net::HTTP::Post.new(uri.path)
      req['Content-Type'] = 'application/json; charset=UTF-8'

      payload = {
        text: text,
        channel: channel,
        link_names: true,
      }

      req.body = payload.to_json

      http.request(req)
    end
  end
end
