require "http/client"
require "colorize"
require "json"

module HostedDanger
  alias L = Logger

  class Logger
    MYM_TOKEN = "feb6396e272a344c8aa6d43e42c59b7ce9f4e9f466a9b4bc973da97196d22c9c"

    def self.info(msg : String, mym = false) : Nil
      log_out("Info".colorize.fore(:green).to_s, msg)
      post_mym(msg) if mym
      nil
    end

    def self.error(msg : String, mym = true) : Nil
      log_out("Error".colorize.fore(:red).to_s, msg)
      post_mym(msg) if mym
      nil
    end

    def self.warn(msg : String, mym = false) : Nil
      log_out("Warn".colorize.fore(:yellow).to_s, msg)
      post_mym(msg) if mym
      nil
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
        token:   MYM_TOKEN,
        message: msg,
      }.to_json

      HTTP::Client.post("https://mym.corp.yahoo.co.jp/api/post", headers, body)
    end
  end
end
