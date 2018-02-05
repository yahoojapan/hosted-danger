require "http/client"
require "colorize"
require "json"

module HostedDanger
  alias L = Logger

  class Logger
    MYM_TOKEN = "0c3781e6201d9680fd64ae02580346a727014c1ef42126d9f541a891943a1bdf"

    def self.info(msg : String, mym = false)
      log_out("Info".colorize.fore(:green).to_s, msg)
      post_mym(msg) if mym
    end

    def self.error(msg : String, mym = true)
      log_out("Error".colorize.fore(:red).to_s, msg)
      post_mym(msg) if mym
    end

    def self.warn(msg : String, mym = false)
      log_out("Warn".colorize.fore(:yellow).to_s, msg)
      post_mym(msg) if mym
    end

    def self.log_out(tag, msg)
      msg_with_tag = "[#{ftime}]: [#{tag}] #{msg}"
      puts msg_with_tag
    end

    def self.ftime : String
      Time.now.to_s("%Y-%m-%d %H:%M:%S")
    end

    def self.post_mym(msg : String)
      headers = HTTP::Headers.new
      headers["Content-type"] = "application/json"

      body = {
        token: MYM_TOKEN,
        message: msg,
      }.to_json

      spawn do
        HTTP::Client.post("https://mym.corp.yahoo.co.jp/api/post", headers, body.to_json)
      end
    end
  end
end
