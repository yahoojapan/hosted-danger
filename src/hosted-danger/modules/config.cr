module HostedDanger
  class Config
    def self.create_from(path : String) : Config?
      return nil unless File.exists?(path)
      return nil unless yaml_file = File.read(path)
      return nil if yaml_file.empty?

      Config.from_yaml(yaml_file)
    rescue e : Exception
      L.error e.message.not_nil!
      return nil
    end

    def self.create(yaml : String) : Config
      Config.from_yaml(yaml)
    end

    alias Events = Array(String)

    YAML.mapping(
      lang: String?,
      dangerfile: String?,
      events: Events?,
      bundler: Bool?,
      npm: Bool?,
      yarn: Bool?,
      exec_close: Bool?,
      no_fetch: Bool?,
    )
  end
end
