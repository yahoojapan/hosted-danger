module HostedDanger
  class Config
    def self.parse(path) : Config?
      return nil unless File.exists?(path)
      return nil unless yaml_file = File.read(path)
      return nil unless yaml = YAML.parse(yaml_file)
      return nil if yaml == nil

      Config.new(yaml)
    rescue e : Exception
      L.error e.message.not_nil!
      return nil
    end

    def initialize(@yaml : YAML::Any)
    end

    def lang : String?
      return nil unless yaml = @yaml
      yaml["lang"]? ? yaml["lang"].as_s : nil
    end

    def dangerfile : String?
      return nil unless yaml = @yaml
      yaml["dangerfile"]? ? yaml["dangerfile"].as_s : nil
    end

    def events : Array(String)?
      return nil unless yaml = @yaml
      yaml["events"]? ? yaml["events"].as_a.map { |event| event.to_s } : nil
    end

    def bundler : Bool?
      return nil unless yaml = @yaml
      yaml["bundler"]? ? (yaml["bundler"].to_s == "true") : nil
    end

    def npm : Bool?
      return nil unless yaml = @yaml
      yaml["npm"]? ? (yaml["npm"].to_s == "true") : nil
    end

    def yarn : Bool?
      return nil unless yaml = @yaml
      yaml["yarn"]? ? (yaml["yarn"].to_s == "true") : nil
    end
  end
end
