require "./hosted-danger/*"

module HostedDanger
  def self.set_envs
    ENV["JENKINS_URL"] = "I'm jenkins! :)"

    raise "Please set DANGER_GITHUB_API_TOKEN" unless ENV["DANGER_GITHUB_API_TOKEN"]?
  end

  def self.run
    set_envs

    server = Server.new
    server.draw_routes
    server.run
  end
end
