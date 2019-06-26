require 'net/https'
require 'json'

module Danger
  class DangerSlack < Plugin
    ENDPOINT = 'http://localhost/slack'.freeze

    def post(text, channel, attachments = nil)
      if text.nil? && attachments.nil?
        raise "slack plugin: text or attachments must exist"
      end

      uri = URI.parse(ENDPOINT)

      http = Net::HTTP.new(uri.host, uri.port)

      req = Net::HTTP::Post.new(uri.path)
      req['Content-Type'] = 'application/json; charset=UTF-8'

      payload = {
        channel: channel,
        link_names: true,
      }

      payload[:text] = text if text
      payload[:attachments] = attachments if attachments

      req.body = payload.to_json

      http.request(req)
    end
  end
end
