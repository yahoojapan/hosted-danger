module HostedDanger
  alias L = Logger

  class Logger
    def self.info(msg : String) : Nil
      log_out("Info".colorize.fore(:green).to_s, msg)
      nil
    end

    def self.error(msg : String) : Nil
      log_out("Error".colorize.fore(:red).to_s, msg)
      nil
    end

    def self.error(e : Exception, payload : String?, show_backtrace : Bool = true) : Nil
      message : String = if error_message = e.message
        error_message
      else
        "No message"
      end

      backtrace = (e.backtrace? || [] of String).join("\n") rescue ""

      message = "<< Message >>:\n#{message}\n\n"
      backtrace = show_backtrace ? "<< Backtrace >>\n```\n#{backtrace}\n```\n\n" : ""
      log = "<< Log >>\n#{payload}"

      L.error "#{message}#{backtrace}#{log}"
    end

    def self.warn(msg : String) : Nil
      log_out("Warn".colorize.fore(:yellow).to_s, msg)
      nil
    end

    def self.log_out(tag, msg)
      msg_with_tag = "[#{ftime}]: [#{tag}] #{msg}"
      puts msg_with_tag unless ENV["SPEC"]? == "true"
    end

    def self.ftime : String
      Time.now.to_s("%Y-%m-%d %H:%M:%S")
    end
  end
end
