require "json"

module HostedDanger
  DANGER_ID = "hosted-danger"

  alias Executable = NamedTuple(
    action: String,
    event: String,
    html_url: String,
    pr_number: Int32,
    sha: String,
    raw_payload: String,
    env: Hash(String, String),
  )

  def self.tokens
    token_path = File.expand_path("../../token.json", __FILE__)
    tokens = JSON.parse(File.read(token_path))
  end

  def self.set_envs
    ENV["JENKINS_URL"] = "I'm jenkins! :)"
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

require "./hosted-danger/modules"
require "./hosted-danger/*"
