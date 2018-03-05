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

  def self.run
    Envs.setup

    server = Server.new
    server.draw_routes
    server.run
  end
end

require "./hosted-danger/modules"
require "./hosted-danger/*"
