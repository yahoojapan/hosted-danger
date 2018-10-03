module HostedDanger
  class ServerConfig
    YAML.mapping(
      githubs: Array(GithubConfig),
      secrets: Array(Secret)?,
    )

    class GithubConfig
      YAML.mapping(
        host: String,
        env: String,
        symbol: String,
        api_base: String,
        raw_base: String,
      )
    end

    class Secret
      YAML.mapping(
        name: String,
        env: String,
      )
    end

    @@server_config_internal : ServerConfig? = nil

    def self.setup(path : String)
      ENV["JENKINS_URL"] = "I'm jenkins! :)"

      @@server_config_internal = ServerConfig.from_yaml(File.read(path))
    end

    def self.access_token_of(git_host : String) : String
      ENV[@@server_config_internal.not_nil!.githubs.find { |g| g.host == git_host }.not_nil!.env]
    end

    def self.api_base_of(git_host : String) : String
      @@server_config_internal.not_nil!.githubs.find { |g| g.host == git_host }.not_nil!.api_base
    end

    def self.raw_base_of(git_host : String) : String
      @@server_config_internal.not_nil!.githubs.find { |g| g.host == git_host }.not_nil!.raw_base
    end

    def self.symbol_to_git_host(symbol : String) : String
      @@server_config_internal.not_nil!.githubs.find { |g| g.symbol == symbol }.not_nil!.host
    end

    def self.secret(name : String) : String
      ENV[@@server_config_internal.not_nil!.secrets.not_nil!.find { |s| s.name == name }.not_nil!.env]
    end
  end
end
