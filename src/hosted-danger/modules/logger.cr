module HostedDanger
  alias L = Logger

  class Logger
    extend Paster

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

    def self.error(e : Exception, payload : String?, show_backtrace : Bool = true, mym : Bool = true) : Nil
      message : String = if error_message = e.message
        error_message
      else
        "No message"
      end

      backtrace : String = if _backtrace = e.backtrace?
        _backtrace.join("\n")
      else
        "No backtrace"
      end

      paster_url = if _payload = payload
                     upload_text(_payload)
                   else
                     "No payload"
                   end

      message = "<< Message >>:\n#{message}\n\n"
      backtrace = show_backtrace ? "<< Backtrace >>\n```\n#{backtrace}\n```\n\n" : ""
      log = "<< Log >>\n#{paster_url}"

      L.error "#{message}#{backtrace}#{log}", mym
    end

    def self.warn(msg : String, mym = false) : Nil
      log_out("Warn".colorize.fore(:yellow).to_s, msg)
      post_mym(msg) if mym
      nil
    end

    def self.log_out(tag, msg)
      msg_with_tag = "[#{ftime}]: [#{tag}] #{msg}"
      puts msg_with_tag unless ENV["SPEC"]? == "true"
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
