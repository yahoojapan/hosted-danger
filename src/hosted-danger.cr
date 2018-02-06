require "./hosted-danger/*"
require "json"

module HostedDanger
  def self.set_envs
    ENV["JENKINS_URL"] = "I'm jenkins! :)"

    token_path = File.expand_path("../../token.json", __FILE__)
    tokens = JSON.parse(File.read(token_path))

    ENV["DANGER_GITHUB_API_TOKEN"] = tokens["access_token"].as_s
    ENV["DRAGON_ACCESS_KEY"] = tokens["dragon_access_key"].as_s
    ENV["DRAGON_SECRET_ACCESS_KEY"] = tokens["dragon_secret_access_key"].as_s
  end

  def self.run
    set_envs

    server = Server.new
    server.draw_routes
    server.run
  end
end
