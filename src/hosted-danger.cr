require "./hosted-danger/*"

module HostedDanger
  def self.set_envs
    token_path = File.expand_path("../../token", __FILE__)

    ENV["JENKINS_URL"] = "I'm jenkins! :)"
    ENV["DANGER_GITHUB_API_TOKEN"] = File.read(token_path).chomp
  end

  def self.run
    set_envs

    server = Server.new
    server.draw_routes
    server.run
  end
end
