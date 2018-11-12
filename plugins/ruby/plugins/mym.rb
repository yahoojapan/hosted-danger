require 'net/https'
require 'json'

module Danger
  class DangerMym < Plugin
    ENDPOINT = 'https://mym.corp.yahoo.co.jp/api/post'.freeze

    def post(comment, token, room = nil)
      uri = URI.parse(ENDPOINT)

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      req = Net::HTTP::Post.new(uri.path)
      req['Content-Type'] = 'application/json'

      payload = {
        token: token,
        message: comment
      }

      if room
        payload[:room] = room
      end
      payload = payload.to_json

      req.body = payload

      https.request(req)
    end
  end
end
