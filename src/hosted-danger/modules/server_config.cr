module HostedDanger
  class ServerConfig
    YAML.mapping(
      githubs: Array(GithubConfig),
      secrets: Array(Secret)?,
      ignores: Array(Ignore)?,
    )

    class GithubConfig
      YAML.mapping(
        host: String,
        user: String,
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

    class Ignore
      YAML.mapping(
        user: String,
        events: Array(String),
      )
    end

    @@server_config_internal : ServerConfig? = nil
    @@env_internal : Hash(String, String) = {} of String => String

    def self.setup(path : String)
      ENV["JENKINS_URL"] = "I'm jenkins! :)"

      @@server_config_internal = ServerConfig.from_yaml(File.read(path))

      @@server_config_internal.not_nil!.githubs.each do |g|
        @@env_internal[g.env] = ENV[g.env]
        ENV.delete(g.env)
      end

      if secrets = @@server_config_internal.not_nil!.secrets
        secrets.each do |s|
          @@env_internal[s.env] = ENV[s.env]
          ENV.delete(s.env)
        end
      end
    end

    def self.githubs : Array(GithubConfig)
      @@server_config_internal.not_nil!.githubs
    end

    def self.access_token_of(git_host : String) : String
      @@env_internal[@@server_config_internal.not_nil!.githubs.find { |g| g.host == git_host }.not_nil!.env]
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

    def self.git_host_to_symbol(git_host : String) : String
      @@server_config_internal.not_nil!.githubs.find { |g| g.host == git_host }.not_nil!.symbol
    end

    def self.secret(name : String) : String
      @@env_internal[@@server_config_internal.not_nil!.secrets.not_nil!.find { |s| s.name == name }.not_nil!.env]
    end

    def self.ignore?(user : String, event : String) : Bool
      app_users = @@server_config_internal.not_nil!.githubs.map { |g| g.user }
      return true if app_users.includes?(user)

      if ignores = @@server_config_internal.not_nil!.ignores
        if ignored_user = ignores.find { |i| i.user == user }
          return ignored_user.events.includes?(event)
        end
      end

      false
    end

    def self.app_user(host : String) : String
      @@server_config_internal.not_nil!.githubs.find { |g| g.host == host }.not_nil!.user
    end
  end
end
