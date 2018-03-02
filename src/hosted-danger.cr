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

  @@envs : JSON::Any?

  def self.envs : JSON::Any
    return @@envs.not_nil! if @@envs

    envs_path = File.expand_path("../../envs.json", __FILE__)
    @@envs = JSON.parse(File.read(envs_path))
    @@envs.not_nil!
  end

  def self.set_envs
    ENV["JENKINS_URL"] = "I'm jenkins! :)"
    ENV["DRAGON_ACCESS_KEY"] = envs["dragon_access_key"].as_s
    ENV["DRAGON_SECRET_ACCESS_KEY"] = envs["dragon_secret_access_key"].as_s
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
