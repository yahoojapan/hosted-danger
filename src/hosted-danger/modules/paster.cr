module HostedDanger
  module Paster
    def upload_text(text : String) : String
      url = "https://mym.corp.yahoo.co.jp/paster"

      post_text = "text=#{text}"

      headers = HTTP::Headers.new
      headers["Accept"] = "*/*"
      headers["ContentLength"] = "#{post_text.bytesize}"

      res = HTTP::Client.post(url, headers, post_text)

      json = JSON.parse(res.body)
      json["url"].as_s
    end
  end
end
