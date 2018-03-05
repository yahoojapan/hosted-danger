module HostedDanger
  class Envs
    # 開発時にしか使用しない
    ENVS_PATH = File.expand_path("../../../../envs.json", __FILE__)

    @@envs_internal = {} of String => String

    def self.setup
      ENV["JENKINS_URL"] = "I'm jenkins! :)"

      if File.exists?(ENVS_PATH)
        L.info "Load env vars as dev environment"

        json = JSON.parse(File.read(ENVS_PATH))

        @@envs_internal["access_token_ghe"] = json["access_token_ghe"].as_s
        @@envs_internal["access_token_partner"] = json["access_token_partner"].as_s
        @@envs_internal["access_token_git"] = json["access_token_git"].as_s
        @@envs_internal["dragon_access_key"] = json["dragon_access_key"].as_s
        @@envs_internal["dragon_secret_access_key"] = json["dragon_secret_access_key"].as_s
      else
        L.info "Load env vars as prod environment"

        @@envs_internal["access_token_ghe"] = ENV["ACCESS_TOKEN_GHE"]
        @@envs_internal["access_token_partner"] = ENV["ACCESS_TOKEN_PARTNER"]
        @@envs_internal["access_token_git"] = ENV["ACCESS_TOKEN_GIT"]
        @@envs_internal["dragon_access_key"] = ENV["DRAGON_ACCESS_KEY"]
        @@envs_internal["dragon_secret_access_key"] = ENV["DRAGON_SECRET_ACCESS_KEY"]

        ENV.delete("ACCESS_TOKEN_GHE")
        ENV.delete("ACCESS_TOKEN_PARTNER")
        ENV.delete("ACCESS_TOKEN_GIT")
        ENV.delete("DRAGON_ACCESS_KEY")
        ENV.delete("DRAGON_SECRET_ACCESS_KEY")
      end

      L.info "All env vars are loaded successfully"
    end

    def self.get(key : String) : String
      @@envs_internal[key.downcase]
    end

    def self.clear
      @@envs_internal.clear if ENV["SPEC"]? == "true"
    end
  end
end
